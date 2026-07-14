# 錯誤處理改善計畫

> 狀態:**規劃完成、尚未實作**。
> 產出自 2026-07-14 的錯誤處理全面審查(Claude Code 對話)。
>
> **工作流程**:實作時從 `main` 開新分支 `fix/error-handling-messages`(**不開 PR,本地 branch 即可**),
> 每完成一個 Phase 就 commit 一次(commit 訊息見文末切分建議),全部完成後再決定合併方式。

---

## 第一部分:現況 — 全 App 錯誤處理方法總覽

### 分層架構

```
Scraper (Map 判別碼) → ApiService facade → Repository (收斂成 bool) → Provider (失敗旗標+登出決策) → UI (retry 畫面)
```

**最高原則(紅線,見文末)**:區分「連不上伺服器」與「伺服器說你沒登入」,
**只有後者可登出使用者**。判別工具:`lib/utils/network_error.dart` 的
`isNetworkError()`(跨平台,刻意不用 `dart:io`)。

### 各功能現行錯誤契約

| 功能 | 回傳型態 | 離線判別 | Session 過期 | 錯誤消費者 |
|------|----------|:---:|:---:|------|
| 個人資訊 (InfoScraper) | `status`: `network_error`/`session_expired`/`error` | ✅ | ✅ **唯一登出來源** | `AuthProvider.init`、`DataProvider.fetchUserInfo` → `handleSessionExpired()` |
| 成績 (GradesScraper) | `success` + `isExpired` | ❌ | ⚠️ 前景被丟棄;僅背景服務讀取 | `GradesRepository.refresh` → bool |
| 畢業審核 (GraduationScraper) | `success` + `isExpired` | ❌ | ⚠️ 被丟棄 | `GraduationRepository` → bool |
| 課表 (ScheduleScraper) | `status` + `isExpired` | ❌ | ⚠️ 被丟棄 | `CourseRepository` → bool |
| 請假記錄 (AbsentScraper) | `status` + `isExpired` | ❌ | ⚠️ 被丟棄 | `absent_screen` **直接呼叫,無快取** |
| 行事曆/假日 (CalendarScraper) | `success` only | ❌ | N/A(公開頁) | 快取服務;內層個別容錯 |
| SSO 登入/TOTP/改密碼 (SsoScraper) | `success` + `message`(解析自頁面)+ `mfaRequired`/`restart` | 由 AuthProvider 事後補判 | N/A | `AuthProvider` |
| 在學證明 (AppApiService) | `Uint8List?` 或 throw `AppApiAuthRequiredException` | 回 null(不分原因) | 401→靜默 refresh 重試一次;無憑證→throw | `yun_report_screen` |

### 現行做得對的(保留,不動)

1. `AuthProvider.init` 三態處理:離線保留快取、確認過期才清 cookie、不明錯誤保守保留
   (`lib/providers/auth_provider.dart:120-170`)
2. Cache-first:`xxxFailed` 只在「失敗**且**無快取」時為 true,離線仍顯示舊資料
   (`lib/providers/data_provider.dart:249-296`)
3. App API 401 自癒(靜默 re-mint token + 重試一次)+ 403 明確不當過期
4. 登入/改密碼 catch 後補查連線,離線顯示 `loginNoNetwork`
5. `change_password_screen.dart:83-89` 的三態分流(離線/通用/學校真實訊息)——**本計畫的樣板**

---

## 第二部分:問題清單

### A. 原始後端錯誤洩漏到 UI(使用者看到 `DioException…`)

| # | 位置 | 問題 |
|---|------|------|
| A1 | `lib/screens/calendar_screen.dart:336` | `_errorMessage = e.toString()` |
| A2 | `lib/screens/course_detail_screen.dart:66` | 直接顯示 scraper 的 `response['message']`(內含 `$e`) |
| A3 | `lib/screens/course_detail_screen.dart:76` | `loadErrorPrefix(e.toString())` |
| A4 | `lib/screens/course_detail_screen.dart:177` | `courseLoadMapDataFailed(e.toString())` |
| A5 | `lib/screens/login_form.dart:127` + `lib/providers/auth_provider.dart:204` | `fetchCaptcha` 線上失敗時 `_error = e.toString()`,經 `auth.error!` fallback 彈出原始例外 |

### B. 語意混淆(不同原因、同一句話)

| # | 問題 | 影響 |
|---|------|------|
| B1 | **登入:伺服器掛掉也說「帳密或驗證碼錯誤」**。`sso_scraper.dart:143-162` 已解析出學校真實原因(`validation-summary-errors`),但 `auth_provider.dart:264` 丟棄硬寫 `loginFailed`;catch 分支也只分「離線/loginFailed」兩態,SSO 500 一樣顯示帳密錯誤 | 最誤導使用者 |
| B2 | **無「服務不可用」分類**:成績/畢業/課表/請假/課程詳情/行事曆連不上子系統時只有通用「載入失敗」 | 使用者無法分辨是自己網路、還是學校系統掛了 |
| B3 | **在學證明**:未註冊(503)/網路失敗/其他錯誤全混成 `yunReportUnavailable`(「請先完成註冊,或稍後再試」)一句 | 已註冊者被叫去「先完成註冊」 |

### C. 結構缺口

| # | 問題 |
|---|------|
| C1 | `isExpired` 旗標在前景是死碼(Repository 收斂成 bool 即丟棄);唯一消費者是 `background_service.dart:53-62` |
| C2 | 除 InfoScraper 外,5 個 scraper 都沒用 `isNetworkError()`,離線與解析失敗不分 |
| C3 | scraper 的 `message` 是寫死繁中(`'抓取成績失敗: $e'`),未走 l10n(A2 修掉洩漏後轉為 log-only 即可接受) |
| C4 | 課表切換學期失敗全靜默(`data_provider.dart:338-362` 的 `selectSemester` / `_prefetchOtherSemesters`),使用者只看到空課表 |

---

## 第三部分:實作計畫(六個 Phase)

### Phase 1 — 統一 scraper 錯誤契約(基礎,其他 Phase 依賴)

為 `GradesScraper`、`GraduationScraper`、`ScheduleScraper`、`AbsentScraper`、
`CalendarScraper`、`SsoScraper` 的 catch 區塊加上 `isNetworkError()` 判別,對外契約統一:

```dart
// 成功
{'success': true, ...}                                             // 或 status: 'success'
// 三種失敗
{'success': false, 'status': 'network_error',   'message': ...}   // 連不上 → UI「無法連線至XX系統」
{'success': false, 'status': 'session_expired', 'message': ...}   // 確認登出(取代散落的 isExpired)
{'success': false, 'status': 'error',           'message': ...}   // 解析失敗等 → 通用載入失敗
```

- `message` 一律**僅供 debug log**,不再進 UI(解 C3)
- **保留** grades 回傳的 `isExpired: true`(向下相容 background_service);其他 scraper 的
  `isExpired` 改為 `status: 'session_expired'`
- ⚠️ 分類順序必須「**先** `isNetworkError(e)` 判離線,**才**判過期」,順序反了會重演紅線 bug
- InfoScraper 已符合,不動

### Phase 2 — 登入錯誤三態分流(B1、A5)

**`AuthProvider`**:
- `login()` 失敗分三態存入 `_error`:
  - `'loginNoNetwork'` — catch 到網路錯誤或事後查離線
  - `'ssoUnavailable'` — 伺服器有回但異常(500/解析不到表單/`loginInit` 失敗)
  - 帳密/驗證碼被明確拒絕 — 有 `validation-summary-errors` 學校原文時優先顯示
    (放新欄位 `_errorDetail` 或 `'loginFailed:<訊息>'`),否則 `loginFailed`
- `fetchCaptcha()` 的 `_error = e.toString()` 改為 `'ssoUnavailable'`(A5 根除)

**`login_form.dart`**:
- 移除 `auth.error!` 原文 fallback;改為 key→l10n 映射 + 學校訊息(比照 change_password 樣板)

### Phase 3 — 「服務不可用」具名文案(B2、C2)

**l10n(`app_zh.arb` + `app_en.arb` 都要,然後 `flutter gen-l10n`)**:

```jsonc
"serviceUnavailable": "無法連線至{service},請確認網路,或稍後再試",
// en: "Cannot reach {service}. Check your network or try again later."
"serviceSso": "單一入口服務網",      // en: "the SSO portal"
"serviceGrades": "成績系統",         // en: "the grades system"
"serviceSchedule": "課表系統",       // en: "the schedule system"
"serviceGraduation": "畢業審核系統", // en: "the graduation audit system"
"serviceAbsent": "請假系統",         // en: "the leave system"
"serviceCalendar": "學校行事曆",     // en: "the school calendar"
"serviceCourseDetail": "課程大綱系統", // en: "the course syllabus system"
"serviceYunReport": "在學證明服務"   // en: "the enrollment certificate service"
```

**傳遞層**:Repository `refresh()` 由 `bool` 改為輕量 enum:

```dart
enum RefreshOutcome { success, networkError, serviceError, sessionExpired }
```

`DataProvider` 各 dataset 除 `xxxFailed` 外新增 `xxxFailReason`(`network`/`service`),
畫面失敗狀態據此顯示「無法連線至成績系統…」或通用「無法載入成績」。

**`absent_screen`**(唯一無快取直連畫面,最優先):依 `status == 'network_error'` 顯示
`serviceUnavailable(serviceAbsent)`,其餘顯示 `absentLoadFailed`。

### Phase 4 — 洩漏點逐一修復(A1–A4)

| 位置 | 修法 |
|------|------|
| A1 calendar | `e.toString()` → `isNetworkError(e) ? serviceUnavailable(serviceCalendar) : loadCalendarFailed`;`_errorMessage` 已存 l10n 成品,移除 `calendar_screen.dart:756` 的 `loadErrorPrefix` 包裝 |
| A2/A3 course_detail | 依 Phase 1 `status` 分流:`network_error` → `serviceUnavailable(serviceCourseDetail)`,其他 → 通用「載入課程資料失敗」;原始 `$e` 只進 `kDebugMode` log |
| A4 map 資料 | `courseLoadMapDataFailed(e.toString())` → 去掉參數改固定文案(arb 移除 placeholder) |
| 收尾 | 檢查 `loadErrorPrefix` 是否已無使用者,若無則從兩個 .arb 刪除 |

### Phase 5 — 在學證明三態(B3)

`AppApiService.getYunReport()` 回傳型別改 sealed result(或加 typed exception):

- **503(未註冊)** → UI:「尚未完成本學期註冊,暫無在學證明」(新 key `yunReportNotRegistered`)
- **網路錯誤** → UI:`serviceUnavailable(serviceYunReport)`
- **其他** → 現行 `yunReportUnavailable`(文案改為不再提「註冊」)
- `AppApiAuthRequiredException` 流程不變
- 同步更新 `test/app_api_service_test.dart`

### Phase 6 — 結構缺口收尾(C1、C4)

- **C4**:`DataProvider.selectSemester` 失敗時設 `semesterLoadFailed` 旗標,
  `schedule_screen` 顯示 snackbar/重試,不再默默空白
- **C1**:Phase 1 統一 `session_expired` 後,Repository 遇 `sessionExpired` outcome
  是否轉呼叫 `handleSessionExpired()` —— **預設採保守方案:只記 log,不登出**
  (理由見文末紅線;維持 InfoScraper 為唯一登出來源)

### 驗收清單(每個 Phase 完成時)

1. `flutter gen-l10n`(改過 .arb 之後)
2. `flutter analyze` 無新警告
3. `flutter test` 全綠
4. `dart format .`(CI 最常見死因)
5. 手動驗證矩陣:
   - 飛航模式 → 每畫面應顯示具名「無法連線至XX」而非通用失敗,且**不被登出**
   - 錯誤帳密 → 顯示帳密錯誤(學校原文優先),而非連線錯誤
   - demo 帳號 → 全部功能不受影響
6. 所有新文案 zh/en 雙語齊備

### 建議 commit 切分(單一 PR、每 Phase 一 commit)

```
1. feat(error): unify scraper error contract with network_error status      (Phase 1)
2. fix(login): distinguish credential errors from SSO unavailability        (Phase 2)
3. feat(l10n): named service-unavailable messages across all screens        (Phase 3)
4. fix(ui): stop leaking raw exceptions to error views                      (Phase 4)
5. fix(yunreport): separate not-registered / offline / generic failures     (Phase 5)
6. fix(schedule): surface semester-switch failures                          (Phase 6)
```

---

## 附錄:紅線 — 為何「只有 session_expired 可登出」不可違反

CLAUDE.md 記錄的歷史 bug:早期版本斷網時抓資料回 `success: false` 被誤當
session 過期 → 離線冷啟動就把使用者登出、清 cookie 與快取,而離線登不回去
(登入需驗證碼)。修好後立為規則:**Never reintroduce that.**

本計畫的兩個交界點:

1. **Phase 6 若讓其他 scraper 的 `session_expired` 觸發登出**,登出判定來源從
   1 個(InfoScraper)變 5 個,誤判面積放大。且這些 scraper 的過期偵測不可靠——
   `absent_scraper.dart:35-37` 自己註明 `contains('Login.aspx')` 會在正常登入時
   誤命中(頁首選單本含登入連結);成績/畢業 scraper 用的正是這種字串比對。
   學校改版即可能集體誤報。→ 故 Phase 6 預設只記 log。
2. **Phase 1 的分類順序**:必須先 `isNetworkError(e)` 判離線、才判過期;
   把離線誤分類成 `session_expired` 又接上登出 = 重演當年 bug。

合規部分:連線狀態(`ConnectivityService`)僅用於**文案措辭**(無網路 vs 服務
不可用),不參與登出決策,符合「connectivity 只能當 UX 優化」規則。
