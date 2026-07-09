# 🎓 YunTool 雲科工具箱

<p align="center">
  <img src="assets/icon/icon.png" alt="YunTool Logo" width="120" height="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);"/>
</p>

<p align="center">
  <a href="https://github.com/Hamsterowo/NYUST-APP/actions"><img src="https://github.com/Hamsterowo/NYUST-APP/actions/workflows/analyze.yaml/badge.svg" alt="Analyze Status"/></a>
  <a href="https://github.com/Hamsterowo/NYUST-APP/actions"><img src="https://github.com/Hamsterowo/NYUST-APP/actions/workflows/build.yaml/badge.svg" alt="Build Status"/></a>
  <img src="https://img.shields.io/badge/Flutter-%3E%3D%203.11.0-02569B?logo=flutter&logoColor=white" alt="Flutter Version"/>
  <img src="https://img.shields.io/badge/Platform-Android-blue" alt="Supported Platforms"/>
  <img src="https://img.shields.io/badge/License-GPLv3-green" alt="License"/>
</p>

---

**雲科工具箱/YunTool** 是一款雲科大學生使用的手機應用程式，提供在手機上更好的單一入口操作介面。本專案為第三方獨立開發，與國立雲林科技大學沒有任何關係。

---

## ✨ 特色

*   📅 **課表瀏覽**：快速瀏覽當前課表，可以查看上課位置以及課程詳細資訊等內容。
*   📊 **成績追蹤**：提供歷年學期成績與排名，快速掌握學期進度。
*   🎓 **畢業學分**：抓取畢業學分頁面，了解畢業所需學分。
*   📄 **在學證明**：透過官方雲科 App 端點（免圖形驗證碼）取得在學證明 PDF，直接於 App 內檢視。
*   🗓️ **學校行事曆**：整合學校重要日程與台灣法定假日，快速瀏覽下個假期以及重要資訊。
*   🔔 **成績更新背景通知 (Background Sync)**：
    *   在背景定期向學校伺服器比對最新成績。
    *   在手機本機上比對，若有新成績公佈即觸發**純本地通知**，不經過任何第三方推播伺服器，速度極快且隱私安全。
*   🔒 **隱私防護等級**：
    *   **無後端伺服器**：所有校務資料及個人基本資訊僅儲存於使用者手機本機。
    *   **密碼不落地**：預設情況下密碼僅存在於登入當下的記憶體中。驗證後取得的登入憑證 (Cookie) 以 AES 加密方式儲存於裝置的**安全儲存區 (Secure Storage)**。
    *   **記住密碼（選用）**：為讓在學證明等 App 端點功能於憑證過期時可自動重新登入，可選擇開啟「記住密碼」；此時**僅儲存密碼的 SHA-256 雜湊（非明文）** 於安全儲存區，且可隨時關閉並清除。

---

## 🛠️ 技術棧與架構設計

本專案遵循現代 Flutter 架構，採 **Repository 模式** 進行資料流控制：`網頁爬蟲 (Scraper) / API ➡️ Drift 本地資料庫 ➡️ Repository Stream ➡️ UI`。

*   **UI / State**: [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) / [Provider](https://pub.dev/packages/provider)
*   **Database**: [Drift](https://pub.dev/packages/drift) (基於 SQLite 的反應式 ORM 資料庫)
*   **Networking**: [Dio](https://pub.dev/packages/dio) + [Cookie Jar](https://pub.dev/packages/cookie_jar)
*   **Scheduler**: [Workmanager](https://pub.dev/packages/workmanager)
*   **Notifications**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
*   **Analytics**: Firebase Core & Analytics & Crashlytics

---

## 🚀 快速開始 (Getting Started)

### 本地開發環境
- Flutter SDK (>= 3.11.0)
- Android Studio / VS Code (需安裝 Flutter & Dart 擴充功能)

### 執行步驟
1. 複製此專案：
   ```bash
   git clone https://github.com/Hamsterowo/NYUST-APP.git
   ```
2. 安裝套件相依性：
   ```bash
   flutter pub get
   ```
3. 產生本地資料庫與 JSON 解析代碼（Drift / Build Runner）：
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. 啟動應用程式（建議以 `--profile` 或 `--release` 測試效能）：
   ```bash
   flutter run
   ```

---

## ⚙️ Google Play 商店上架與測試帳號

為了方便商店審核團隊 (Google Play Reviewers) 或開發測試者在沒有真實雲科大 SSO 學生帳號的情況下體驗 App，我們提供了**單一來源 Demo 模式**：

*   **測試帳號 (Username)**: `demo`
*   **測試密碼 (Password)**: *（任意填寫即可）*
*   **驗證碼 (CAPTCHA)**: *（任意填寫即可）*

> 💡 **Demo 模式特點**：使用該帳號登入後，App 會啟用 `MockData`，提供橫跨 3 個學年、5 個學期的完整虛擬成績、課表、畢業門檻以及行事曆資料，所有學分數與圖表皆完美契合，可供深度審核。

---

## 📦 打包發布 (Production Build)

發布版本時請進行打包（以 Android App Bundle 為例，上架 Play 商店專用）：

### Android App Bundle (AAB - 上架專用)
```bash
flutter build appbundle --release --dart-define=USE_FIREBASE=true
```

### 參數說明
*   `--dart-define=USE_FIREBASE=true`：注入變數，啟用 Firebase 統計與當機回報功能。

---

## 📜 法律聲明與授權 (License)

*   **免責聲明**：本應用程式為第三方開源專案，與國立雲林科技大學官方單位無任何隸屬或合作關係。使用者輸入的帳號密碼僅直接與學校伺服器進行通信。
*   **授權條款**：本專案採用 **[GNU General Public License v3.0 (GPL-3.0)](LICENSE)** 授權開源。歡迎雲科大同學與開發者一同參與開發與貢獻！

