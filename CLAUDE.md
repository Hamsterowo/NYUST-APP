# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

YunTool (雲科工具箱, package name `yun_tool`, formerly "NYUST+") is a third-party Flutter client for National Yunlin University of Science and Technology's (雲科大/YunTech) student portal. It works by scraping the official SSO/WebNewCAS/eStudent HTML pages directly from the client using `dio` — there is no official API. Targets: Android, iOS, Web, Windows, Linux, macOS.

## Commands

```bash
flutter pub get                    # install dependencies
flutter run                        # run on connected device/emulator
flutter analyze                    # static analysis (flutter_lints)
flutter test                       # run all tests
flutter test test/widget_test.dart # run a single test file
flutter gen-l10n                   # regenerate lib/l10n/app_localizations*.dart after editing the .arb files
```

Release builds (see `README.md` / `build.sh`):

```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
flutter build web --dart-define=API_SECRET=$API_SECRET
```

`API_SECRET` is compiled in via `--dart-define` and sent as the `X-Nyust-App-Secret` header on every request (see `ApiService`). There is no `.env` file — it must be supplied at build time.

## Architecture

### Data flow: UI (Riverpod) → Repository → ApiService → Scrapers → School portal

- **State management is Riverpod** (`flutter_riverpod`), not the `provider` package. `main.dart` wraps the app in a `ProviderScope`; screens are `ConsumerWidget` / `ConsumerStatefulWidget` and read state via `ref.watch` / `ref.read`. All providers are declared in **`lib/providers/providers.dart`**.
- **`lib/providers/providers.dart`** — the Riverpod DI root. `authProvider` and `dataProvider` are `ChangeNotifierProvider`s wrapping the `AuthProvider` / `DataProvider` `ChangeNotifier`s below (the login state machine is kept intact rather than rewritten as `Notifier`s). `dataProvider` is created **lazily** — on first read by a data screen — and reads `authProvider` via `ref.read`. Also holds `navIndexProvider` (`StateProvider<int>`, the bottom-nav tab index — replaces the old `NavigationProvider`) and `scrollToNotificationProvider` (`StateProvider<bool>`, the cross-tab "scroll to the grade-notification setting" signal).
- **`lib/providers/auth_provider.dart`** — owns the single `ApiService` instance, session state, login/logout, and a secure-storage-cached copy of user info. Exposes `onLoginSuccess` / `onLogoutCallback` hooks that `DataProvider` wires itself into.
- **`lib/providers/data_provider.dart`** — subscribes to the repository Drift streams and mirrors grades/graduation/schedule into memory (repositories persist to Drift + `flutter_secure_storage`), so screens never call the API directly. Its `_init()` calls `prefetchAll()` when `auth.isLoggedIn` is already true at construction, and wires the `onLoginSuccess` / `onLogoutCallback` hooks for later transitions. `prefetchAll()` fetches sequentially (not in parallel) with small delays between calls — this is intentional, to avoid `CookieJar` race conditions when the underlying scraper HTTP calls run concurrently.
- **`lib/services/api_service.dart`** — the single `Dio` instance for the whole app, plus a facade over per-feature scrapers. Two request styles coexist on the same `Dio` instance: relative paths (e.g. `/api/policy/terms`, `/api/report`) hit `baseUrl` (`https://cf-api.nyust-plus.com`, the app's own backend for ToS/bug-reports), while scrapers issue **absolute** URLs against `webapp.yuntech.edu.tw` which bypass `baseUrl`. `ApiService.init()` is idempotent/guarded against concurrent double-init (`_initStarted`/`_isInit`).
- **`lib/services/scrapers/*`** — one scraper per school feature (`SsoScraper`, `InfoScraper`, `ScheduleScraper`, `GradesScraper`, `GraduationScraper`, `CalendarScraper`), all extending `BaseScraper` (`lib/services/scrapers/base_scraper.dart`). `BaseScraper.getWithRedirects` manually follows both HTTP 302 redirects and the school portal's JS `var redirectUrl = '...'` redirect pages, since the portal doesn't always use clean HTTP redirects. Scrapers parse HTML with `package:html` — when a portal page structure changes, the fix is almost always in the relevant scraper's DOM selectors, not in `ApiService`.
- **`LanguageInterceptor`** (bottom of `api_service.dart`) rewrites requests to WebNewCAS/eStudent pages to append `?lang=zh-TW|en` based on the current locale, since the school portal is locale-aware via query param.

### Routing

Routing is **`go_router`** (`lib/router/app_router.dart`, the global `appRouter`), used via `MaterialApp.router` on the mobile/native path. Declared routes: `/` → `SplashWrapper` (the custom splash animation stays here and shows `LoginScreen` or `HomeScreen` inline based on auth), `/grades`, `/graduation`. `HomeScreen`'s five-tab bottom nav is a plain `IndexedStack` driven by `navIndexProvider` (kept as an `IndexedStack` rather than a `StatefulShellRoute` specifically so the splash-overlay crossfade in `SplashWrapper` is preserved). Detail pages (course detail, web view, bug report, terms) are still pushed imperatively with `Navigator.push(MaterialPageRoute(...))` — go_router only owns the top-level routes. The background grade notification deep-links via `appRouter.push('/grades')` (see `NotificationService`).

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
