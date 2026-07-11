# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

YunTool (雲科工具箱, package name `yun_tool`, formerly "NYUST+") is a third-party Flutter client for National Yunlin University of Science and Technology's (雲科大/YunTech) student portal. It works primarily by scraping the official SSO/WebNewCAS/eStudent HTML pages directly from the client using `dio` — there is no official *public* API. A few features additionally use the **captcha-free app endpoint** (`MobileAppService`, the private Bearer-token backend the official mobile app uses, reverse-engineered — see the "App endpoint" section below and `docs/mobile_api.md`). Targets: Android, iOS, Web, Windows, Linux, macOS.

## Commands

```bash
flutter pub get                    # install dependencies
flutter run                        # run on connected device/emulator
flutter analyze                    # static analysis (flutter_lints)
flutter test                       # run all tests
flutter test test/widget_test.dart # run a single test file
flutter gen-l10n                   # regenerate lib/l10n/app_localizations*.dart after editing the .arb files
dart format .                      # ALWAYS run before committing — CI ("Analyze") fails on unformatted code
```

**Before every commit, run `dart format .`** (or `dart format` on the files you touched). The GitHub Actions "Analyze" workflow runs `dart format --output=none --set-exit-if-changed .` and fails the check if any file is unformatted — this is the most common CI failure. `flutter analyze` passing is not enough; formatting is checked separately.

Release builds — the APK/AAB are produced by CI (`.github/workflows/build.yaml`); web by `build.sh`:

```bash
flutter build apk --release --dart-define=USE_FIREBASE=true
flutter build appbundle --release --dart-define=USE_FIREBASE=true
flutter build web
```

The app has **no self-hosted backend** — every request goes to school portals (or public CDNs) as absolute URLs, so no build-time secret is required.

## Architecture

### Data flow: UI (Riverpod) → Repository → ApiService → Scrapers → School portal

- **State management is Riverpod** (`flutter_riverpod`), not the `provider` package. `main.dart` wraps the app in a `ProviderScope`; screens are `ConsumerWidget` / `ConsumerStatefulWidget` and read state via `ref.watch` / `ref.read`. All providers are declared in **`lib/providers/providers.dart`**.
- **`lib/providers/providers.dart`** — the Riverpod DI root. `authProvider` and `dataProvider` are `ChangeNotifierProvider`s wrapping the `AuthProvider` / `DataProvider` `ChangeNotifier`s below (the login state machine is kept intact rather than rewritten as `Notifier`s). `dataProvider` is created **lazily** — on first read by a data screen — and reads `authProvider` via `ref.read`. Also holds `navIndexProvider` (`StateProvider<int>`, the bottom-nav tab index — replaces the old `NavigationProvider`) and `isOnlineProvider` (`StreamProvider<bool>`, online/offline status from `ConnectivityService`, used by the offline banner). The grade-notification toggle is shared between the settings tab and the grades-screen bell via `GradeNotificationService` (`lib/services/grade_notification_service.dart`); the grades bell opens an in-place bottom sheet (`lib/widgets/grade_notification_sheet.dart`) rather than navigating to settings.
- **`lib/providers/auth_provider.dart`** — owns the single `ApiService` instance, session state, login/logout, and a secure-storage-cached copy of user info. Exposes `onLoginSuccess` / `onLogoutCallback` hooks that `DataProvider` wires itself into.
- **`lib/providers/data_provider.dart`** — subscribes to the repository Drift streams and mirrors grades/graduation/schedule into memory (repositories persist to Drift + `flutter_secure_storage`), so screens never call the API directly. Its `_init()` calls `prefetchAll()` when `auth.isLoggedIn` is already true at construction, and wires the `onLoginSuccess` / `onLogoutCallback` hooks for later transitions. `prefetchAll()` fetches sequentially (not in parallel) with small delays between calls — this is intentional, to avoid `CookieJar` race conditions when the underlying scraper HTTP calls run concurrently.
- **`lib/services/api_service.dart`** — the single `Dio` instance for the whole app, plus a facade over per-feature scrapers. There is no app backend: every request is an **absolute** URL against `webapp.yuntech.edu.tw` (or a public CDN, e.g. the calendar/holiday data), so `Dio` has no `baseUrl`. `ApiService.init()` is idempotent/guarded against concurrent double-init (`_initStarted`/`_isInit`). The privacy-policy consent gate renders the repo-root `PRIVACY.zh-TW.md` / `PRIVACY.en.md` (bundled as assets — the same files GitHub displays, single source of truth), parsed by `lib/data/privacy_policy.dart` and shown by `lib/screens/privacy_policy_screen.dart`; `SplashWrapper` shows it once and re-shows it when the front-matter `version:` changes (bump both files' `version:` on any substantive policy change). Report/logout are rows in the settings card, with report opening an email/Discord chooser. `ApiService` also exposes `appApi` (an `AppApiService`) — the isolated client for the captcha-free app endpoint (see the "App endpoint" section).
- **`lib/services/scrapers/*`** — one scraper per school feature (`SsoScraper`, `InfoScraper`, `ScheduleScraper`, `GradesScraper`, `GraduationScraper`, `CalendarScraper`), all extending `BaseScraper` (`lib/services/scrapers/base_scraper.dart`). `BaseScraper.getWithRedirects` manually follows both HTTP 302 redirects and the school portal's JS `var redirectUrl = '...'` redirect pages, since the portal doesn't always use clean HTTP redirects. Scrapers parse HTML with `package:html` — when a portal page structure changes, the fix is almost always in the relevant scraper's DOM selectors, not in `ApiService`.
- **`LanguageInterceptor`** (bottom of `api_service.dart`) rewrites requests to WebNewCAS/eStudent pages to append `?lang=zh-TW|en` based on the current locale, since the school portal is locale-aware via query param.

### App endpoint (MobileAppService / Bearer token)

Most features scrape HTML, but a few use YunTech's **captcha-free app endpoint** — the private Bearer-token backend the official mobile app uses, reverse-engineered (full spec: `docs/mobile_api.md`). These are **two independent auth worlds** and must stay that way:
- web login (captcha) → `.YunTechSSO` cookie → the scrapers above
- app login (`POST /Token`) → Bearer token → `/api/...` features

- **`lib/services/app_api/app_api_service.dart`** (`AppApiService`) — an **isolated** `Dio` (its own instance, **no cookie jar**) against `https://webapp.yuntech.edu.tw/MobileAppService`. The no-cookie-jar isolation is deliberate: the `.YunTechSSO` cookie that `/Token` returns must never clobber the web-login session the scrapers depend on. Every request carries the reverse-engineered `X-User-Nonce` header (built by `lib/utils/yuntech_app_crypto.dart`, which also does the SHA-256 password hashing). Currently only **在學證明** uses it (`getYunReport()` → PDF bytes), reached from an info-screen card via `lib/screens/yun_report_screen.dart`.
- **Login/lifecycle** — after a successful captcha web login, `AuthProvider.login` also calls `appApi.login(username, password, remember: …)` in the background (failure is non-fatal, never blocks web login); `init()` calls `appApi.loadPersisted()`; `logout()` calls `appApi.clear()`.
- **Token lifetime & refresh** — the Bearer token lasts **~90 days** and there is **no refresh-token endpoint**, so re-login is the only way to renew (this matches the official app, which also just relies on the long token + manual re-login). Refresh is **reactive on HTTP 401**: `_authedGetBytes` silently re-mints the token and retries once; **403 (nonce/permission) is NOT treated as expiry.** When it cannot refresh (no credential), it throws `AppApiAuthRequiredException`.
- **Remember password (opt-in, default OFF)** — to renew silently across the ~90-day boundary without a fresh captcha login, the app can persist the **SHA-256 hash** of the password (`app_api_pwd_hash`) — **never the plaintext**; the hash is irreversible and unusable for the web SSO login. It is kept in memory for the session regardless, and persisted only when the user opts in (login-screen checkbox, or the credential settings page). Toggling remember off deletes the persisted hash immediately but leaves the in-memory copy until app restart (the credential page shows a hint about this). Secure-storage keys: `app_api_access_token`, `app_api_user_id`, `app_api_pwd_hash`, `app_api_token_expiry` (display only) — all cleared on `logout()`.
- **UI** — when the token expired with no saved credential, `showAppApiPasswordDialog` (`lib/widgets/app_api_password_dialog.dart`) prompts for the password on-demand. That dialog is parameterised and reused by the **App Credential** settings page (`lib/screens/credential_screen.dart`, a row in `profile_screen.dart`, hidden for the mock account), which shows token status / approximate expiry and the remember toggle. All strings here are bilingual — edit both `.arb` files then `flutter gen-l10n`.

### Offline handling & session resilience

The app is **cache-first**: repositories persist to Drift + `flutter_secure_storage`, so already-fetched grades/graduation/schedule/calendar render from local cache with no network. The governing rule is **distinguish "can't reach the server" from "the server says you're logged out" — only the latter may log the user out.** (Historically a bare network failure surfaced as `success: false` and got treated as a logout, which logged users out on offline cold-start. Never reintroduce that.)

- **`lib/utils/network_error.dart`** — `isNetworkError(e)` classifies an exception as a connectivity failure (offline / timeout / DNS) vs. a real server response. It deliberately avoids `dart:io` (`SocketException`) so it still compiles on Web; it keys off `DioException.type` plus string matching on the inner error.
- **Scraper error contract** — `InfoScraper.getUserInfo()` returns a `status` discriminator: `network_error` (offline — **never** treat as logout), `session_expired` (reached the portal but landed on the login page / no user info), or `error` (other/parse failure). Other scrapers still return a plain `{success: false}`; extend them with the same helper when their offline behaviour matters.
- **`AuthProvider.init()`** loads the cached user first (so `isLoggedIn` is true immediately), **skips online validation entirely when offline** (via `ConnectivityService`), and when it does validate: keeps the cached session on `network_error` and on ambiguous errors, and only clears cookies/cache + logs out on a positive `session_expired`.
- **`AuthProvider.handleSessionExpired()`** wires the previously-dead `onSessionExpired` hook into a full `logout()`. `DataProvider.fetchUserInfo()` calls it when an **online** refresh reports `session_expired`, giving real mid-session logout instead of the old startup-only inference.
- **`lib/services/connectivity_service.dart`** (`connectivity_plus`) collapses `ConnectivityResult` into a simple online `bool`, exposed as `isOnlineProvider`. `DataProvider` watches it and re-runs `prefetchAll()` on an offline→online transition (which also re-validates the session); `HomeScreen` shows an offline banner above the floating bottom nav, and the login screen shows a `loginNoNetwork` message instead of the generic credential error. Connectivity is **UX/optimization only** — the authoritative logout decision is always the request-result classification above, never the connectivity flag (which only reflects a network interface, not real reachability).

### Routing

Routing is **`go_router`** (`lib/router/app_router.dart`, the global `appRouter`), used via `MaterialApp.router` on the mobile/native path. Declared routes: `/` → `SplashWrapper` (the custom splash animation stays here and shows `LoginScreen` or `HomeScreen` inline based on auth), `/grades`, `/graduation`. `HomeScreen`'s five-tab bottom nav is a plain `IndexedStack` driven by `navIndexProvider` (kept as an `IndexedStack` rather than a `StatefulShellRoute` specifically so the splash-overlay crossfade in `SplashWrapper` is preserved). The nav bar itself is a custom floating pill: a rounded "pill" indicator slides behind the selected tab (`AnimatedPositioned` inside a `LayoutBuilder`/`Stack`), with the offline banner rendered just above it. Detail pages (course detail, web view, bug report, terms) are still pushed imperatively with `Navigator.push(MaterialPageRoute(...))` — go_router only owns the top-level routes. The background grade notification deep-links via `appRouter.push('/grades')` (see `NotificationService`).

### Mock/debug mode

Logging in with username `debug` or `test` (case-insensitive) sets `ApiService.isMockMode = true` and short-circuits `getUserInfo`/`getGrades`/`getGraduation`/`getSchedule` to return hardcoded sample data instead of hitting the network — used for UI development without real credentials. The mock user's fixed ID `D11012345` is also how `AuthProvider.init()` detects a cached mock session on cold start.

### Platform-conditional code

Two services use Dart's conditional-import pattern to abstract platform differences behind a shared interface, selected at compile time:
- `lib/services/cookie_manager/` — `cookie_manager_api.dart` exports `cookie_manager_io.dart` (native), `cookie_manager_web.dart` (`dart.library.html`), or `cookie_manager_stub.dart`.
- `lib/utils/pwa_interop.dart` — exports `pwa_web.dart` (`dart.library.js_interop`) or `pwa_stub.dart`.

`main.dart` also branches at runtime: `kIsWeb` + `defaultTargetPlatform` (windows/macOS/linux) renders a plain `MaterialApp` with `DesktopScreen`, instead of the mobile-first `MaterialApp.router` (`appRouter`) whose `/` route is `SplashWrapper` → `LoginScreen`/`HomeScreen`.

### Background grade-check notifications

`lib/services/background_service.dart` registers a `workmanager` periodic task (`checkGradesTask`) that runs in a separate isolate: it spins up its own `ApiService`, checks for saved cookies, fetches grades, and diffs against the secure-storage-cached copy via `lib/utils/grades_comparator.dart`, firing a local notification (`NotificationService`) only when something actually changed. This only runs on native platforms (guarded by `!kIsWeb` in `main.dart`).

### Localization

Source strings live in `lib/l10n/app_zh.arb` (template/primary) and `app_en.arb`; `lib/l10n/app_localizations*.dart` are generated by `flutter gen-l10n` (config in `l10n.yaml`) — do not hand-edit the generated files, edit the `.arb` files and regenerate.

**All user-facing text is bilingual — every text change must be made in BOTH the zh and en versions.** This applies to the two `.arb` files (add/edit/delete keys in both, then regenerate) and to the repo-root `PRIVACY.zh-TW.md` / `PRIVACY.en.md` (bundled as assets and rendered in-app; keep their front-matter `version:` identical). Never change one language and leave the other stale.
