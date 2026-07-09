# YunTech MobileAppService API（行動雲科 App 端點）

> 由官方「行動雲科」App（`tw.edu.yuntech.yuntechapp`，.NET MAUI）反編譯而得的**免驗證碼** App 專用 API。
> 現行的 [`SsoScraper`](../lib/services/scrapers/sso_scraper.dart) 走網頁 SSO（`YunTechSSO/Account/Login`）需要圖片驗證碼；本 API 是官方 App 用的替代路徑，**登入不需驗證碼**。
>
> ⚠️ 反編譯自官方 App，僅供本第三方 client 互通參考。此文件為規格整理（非官方文件），端點與欄位可能隨官方改版而變動。

## Base URL

```
https://webapp.yuntech.edu.tw/MobileAppService
```

所有 `/api/...` 路徑都相對於此 base。登入端點 `/Token` 也是。

---

## 1. 登入（OAuth2 Resource Owner Password grant）

```
POST https://webapp.yuntech.edu.tw/MobileAppService/Token
Content-Type: application/x-www-form-urlencoded

grant_type=password&username=<學號>&password=<SHA256(密碼) 小寫hex>
```

- **密碼要先做 SHA-256（小寫 hex）再送**，不是明文。（`CryptUtils.GetSha256Hash`，`ToString("x2")`）
- 成功 → `200` + JSON：`access_token`、`expires_in`（秒）、`UserName`、`UserType`（`S`=學生 / `FutureStudent`=新生…）
- 帳密錯 → OAuth `invalid_grant`（實測假帳號回 `400`）

回應處理（來自 `LoginPageViewModel.ExecuteLoginCommand`）：
```
AccessToken = json["access_token"]
AccessTokenExpirationDate = now + expires_in 秒（無則預設 24h）
UserName = json["UserName"]
```

### 本 client（[`AppApiService`](../lib/services/app_api/app_api_service.dart)）的憑證處理

- **token 效期**：實測 `expires_in ≈ 7775999`（約 90 天）。官方 App 無 refresh token，**重新 `POST /Token` 是取得新 token 的唯一途徑**；本 client 亦同。`expires_in` 會換算成到期時間存起來，**僅供設定頁「應用程式憑證」顯示用**，不參與更新判斷。
- **反應式更新（reactive on 401）**：呼叫 `/api/...` 收到 `401` 時，若有可用憑證就靜默重登一次再重試；沒有則丟 `AppApiAuthRequiredException`，由 UI 跳出密碼輸入框。`403`（nonce / 權限）**不**視為過期、不觸發重登。
- **記住密碼（opt-in）**：登入畫面與憑證頁可選擇記住密碼。記住的是 **`SHA-256(密碼)` 雜湊**（就是 `/Token` 要送的值），存在 `flutter_secure_storage`（key `app_api_pwd_hash`）；**不存明文**。雜湊無法還原明文，也無法用於網頁 SSO 登入（網頁端有驗證碼）。
- **兩層憑證**：登入當下的雜湊會留在記憶體供本次執行期間靜默重登；勾了記住才會**持久化**跨重啟。未記住時，重啟後 token 過期就走 on-demand 密碼輸入。
- 儲存的 secure-storage keys：`app_api_access_token`、`app_api_user_id`、`app_api_pwd_hash`（記住時）、`app_api_token_expiry`。登出（`clear()`）會一併清除。

---

## 2. 每個 API 請求都要帶的 Header

| Header | 值 |
|---|---|
| `Authorization` | `Bearer {access_token}` |
| `X-User-App-Platform` | `Android` 或 `iOS` |
| `X-User-App-Version-Name` | `1.10.3` |
| `X-User-Nonce` | 見下方演算法（Base64） |

> **版本 header 不被強制檢查**：官方最新 App 的實際版本是 `1.12.5`，但程式裡寫死的 `UserAppVersionName` 還停在 `1.10.3`（官方忘了更新），照樣能用。所以送 `1.10.3` 最安全，但務必與 nonce 明文裡的 `version=` 一致。

### X-User-Nonce 演算法（`HelperBase.GetNonce`）

明文：
```
appid=yuntechapp&userid={學號}&ts={unix秒}&version=1.10.3
```
以 AES-CBC/PKCS7 加密後 Base64。金鑰與 IV 由 PBKDF2 導出：

```
derived = PBKDF2(
  password = "9537730CFB3C11175889F67CF2CD3F09",   // aesKey = str1 + str3
  salt     = "B2B45FE7D3566B34",                   // aesSalt = str2 + str4
  iterations = 1000,
  hash = SHA1,
  length = 32 bytes)
AES key = derived[0..16)
AES IV  = derived[16..32)
```

（登入 `/Token` 時 `userid` 還是空的，代表伺服器對 nonce 內 userid 不做嚴格比對。）

#### Dart 實作草稿（用 `crypto` + `pointycastle` 或 `encrypt`）

```dart
// 依賴：crypto, pointycastle（或 encrypt）
String sha256Hex(String s) =>
    sha256.convert(utf8.encode(s)).toString(); // 小寫 hex

String buildNonce(String studentId) {
  final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final plain = 'appid=yuntechapp&userid=$studentId&ts=$ts&version=1.10.3';
  final derived = _pbkdf2(
    utf8.encode('9537730CFB3C11175889F67CF2CD3F09'),
    utf8.encode('B2B45FE7D3566B34'),
    1000, 32); // PBKDF2-HMAC-SHA1
  final key = derived.sublist(0, 16);
  final iv  = derived.sublist(16, 32);
  final ct  = _aesCbcPkcs7Encrypt(key, iv, utf8.encode(plain));
  return base64.encode(ct);
}
```

---

## 3. 憑證釘選（不影響第三方 client）

App 在 `HttpClientHelper.ValidateServerCertificate` 做 SHA-256 public-key pinning：
- `/api/User/GetServerInfo` 這支**跳過驗證**（用來抓伺服器憑證資訊，是登入後第一支呼叫）。
- 其餘比對 pinned 值或硬編碼 `b15e2d93bc3f9f7718e90e143b64299d90f31b92682ff68bf915b0e2c5c4a206`。

這是「App 驗證伺服器」，**dio / Flutter client 用一般 TLS 即可，不需複製**（雲科憑證是公開受信任的）。

---

## 4. 端點目錄

回傳除特別註明外皆為 JSON。日期格式看各端點（多為 `yyyy-MM-dd` 或 `yyyyMMdd`）。

### 🎓 在學證明
| 端點 | 說明 | 回傳 |
|---|---|---|
| `GET /api/User/GetYunReport` | 本學期在學證明 | **PDF bytes**（未註冊 → 503） |

### 👤 使用者 / 帳號
| 端點 | 說明 |
|---|---|
| `GET /api/User/GetServerInfo` | 伺服器資訊（登入後第一支，免 Bearer / 跳過 pin） |
| `GET /api/User/GetUserProperties` | 個人基本資料 |
| `GET /api/User/GetUserPhoto` | 個人照片（圖片 bytes） |
| `GET /api/User/GetCovid19Passport` | 疫苗接種資料 |
| `POST /api/User/ContactPhoneSearch` | 校內電話查詢（form body） |
| `GET /api/User/Signout` | 登出 |

### 📊 成績
| 端點 | 說明 |
|---|---|
| `GET /api/StudScore/GetStudSeme` | 學期清單 |
| `GET /api/StudScore/GetStudSemeScore` | 學期成績 |
| `GET /api/StudScore/GetStudCourseScore?acadYear={}` | 學年各科成績 |
| `GET /api/StudScore/GetSemeRankList` | 學期排名 |

### 📚 課程
| 端點 | 說明 |
|---|---|
| `GET /api/StudentCourse/GetStudCourseInfo?acadYear={}&semeType={}` | 我的課表 |
| `GET /api/StudentCourse/GetCourseInfo?acadYear={}&semeType={}&currentSubj={}` | 課程詳情 |
| `GET /api/StudentCourse/GetCourseChangeLog?beginDate={}&endDate={}` | 加退選紀錄 |
| `GET /api/AcadSeme/GetAcadSeme?beginDate={}` | 學年期資訊 |

### 🗓️ 出缺勤 / 工讀 / 校園卡
| 端點 | 說明 |
|---|---|
| `GET /api/StudAbsent/GetStudAbsent?acadYear={}&semeType={}` | 缺曠 |
| `GET /api/StudRollCalls/GetStudRollCalls?beginDate={}&endDate={}` | 點名紀錄 |
| `GET /api/StudentWorkStudy/GetStudWorkStudyDaily?startDate={}&endDate={}` | 工讀日誌 |
| `GET /api/CardService/GetRecords?year={}&month={}` | 校園卡刷卡紀錄 |
| `GET /api/CardService/GetRecords?pStartDate={}&pEndDate={}` | 同上（日期區間版，`yyyy-MM-dd HH:mm`） |

### 📅 行事曆 / 活動
| 端點 | 說明 |
|---|---|
| `GET /api/Date/GetHolidayDates?year={}` | 假日 |
| `GET /api/YunTechEvents/GetEvents?startDate={}&endDate={}` | 校園行事曆 |
| `GET /api/YunTechActivities/GetActivities?startDate={}&endDate={}` | 活動列表（`yyyyMMdd`） |
| `GET /api/YunTechActivities/GetUserActivities?startDate={}&endDate={}` | 我報名的活動 |

### 📖 圖書館
| 端點 | 說明 |
|---|---|
| `GET /api/LibSearch/SearchTitle?title={}` | 書名查詢 |
| `GET /api/LibSearch/SearchAuthor?author={}` | 作者查詢 |
| `GET /api/LibSearch/SearchKeyword?keyword={}` | 關鍵字查詢 |

### 🚆 交通（MOTC）
| 端點 | 說明 |
|---|---|
| `GET /api/MOTCHelper/GetTRAStations` / `GetTRATrains` | 台鐵 站 / 車次 |
| `GET /api/MOTCHelper/GetTHSRStations` / `GetTHSRTrains` / `GetTHSRBusTimetableV2` | 高鐵 站 / 車次 / 接駁 |

### 🧑‍💼 差勤（Pemis，教職員導向）
| 端點 | 說明 |
|---|---|
| `GET /api/Pemis/GetLeaveRecordInfo?year={}&leaveType={}` | 請假紀錄 |
| `GET /api/Pemis/GetLeaveStatistics` | 請假統計 |
| `GET /api/Pemis/GetMembersLeaveInformation?pDeptCode={}&pDateValue={}` | 部門請假 |
| `GET /api/Pemis/GetWorkOvertimeInformation?year={}&month={}` | 加班資訊 |
| `GET /api/Pemis/GetAvailableDepartmentList` | 部門清單 |

### 🆘 其他
| 端點 | 說明 |
|---|---|
| `POST /api/EmergHelp/SendEmergHelpMessageAsync` | 緊急求助訊息 |
| `POST /api/EmergHelp/SendEmergHelpPhotoAsync` | 緊急求助照片 |
| `POST /api/YunTechAppLogs/SendLogs` | App 記錄回傳 |

---

## 5. WebView 服務（非 API，帶 cookie session 開網頁）

App 部分功能不是打 API，而是開帶登入 session 的網頁：

| 功能 | URL |
|---|---|
| 線上成績單及證明書**申請** | `https://webapp.yuntech.edu.tw/WebNewCAS/eApply/Certificate/` |
| 課程計畫查詢 | `https://webapp.yuntech.edu.tw/WebNewCAS/Course/Plan/Query.aspx?{...}` |
| 選課 | `https://webapp.yuntech.edu.tw/WebNewCAS/StudentFile/Course/` |
| 活動報名 | `https://webapp.yuntech.edu.tw/Activities/...`（cookie: `yuntechapp`） |

> 「在學證明」(`GetYunReport`) 是原生 API 直接給 PDF；上表「證明書**申請**」是走教務處申請紙本流程，兩者不同。

---

## 6. 反編譯來源（重現步驟）

1. `adb pull` 取 `base.apk` + `split_config.arm64_v8a.apk`
2. 框架判定：.NET MAUI（C#），程式在 `libaot-YunTechApp.dll.so` / `libassembly-store.so`
3. `libassembly-store.so` 是 LZ4（`XALZ`）壓縮 → 解壓取出 `YunTechApp.dll`
4. 用 `ilspycmd`（靠 .NET 8 runtime，免裝 SDK）反編譯
5. 關鍵類別：`HttpClientHelper`、`LoginPageViewModel`、`UserHelper`、`HelperBase`、`CryptUtils`、`Settings`

原始反編譯檔另存於 gitignore 的 `reverse-engineering/`（不進版控）。
