# 🎓 NYUST+

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

> **A Better Yuntech App** - 為雲科大同學打造的第三方校務系統 App，提供更流暢、直觀的使用體驗。

## ✨ 特色功能

- 📅 **智慧課表**：直觀的週課表視圖，點擊課程即可查看教室位置與詳細資訊。
- 📊 **成績查詢**：整合各學期成績，支援歷年成績清單與平均 GPA 查看。
- 🎓 **畢業審核**：視覺化呈現畢業學分進度，快速掌握還缺哪些課程。
- 🗓️ **學校行事曆**：整合學校官方重要日程，支援日曆視圖。
- 🔍 **校園總覽**：彙整個人常用資訊，一進 App 就能看到最重要的資訊。
- 💻 **多平台支援**：完美適配手機端 (Android/iOS) 與電腦網頁端。

## 🛠️ 技術棧

- **Framework**: [Flutter](https://flutter.dev/) (Channel Stable)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Networking**: [Dio](https://pub.dev/packages/dio) with [Cookie Manager](https://pub.dev/packages/dio_cookie_manager)
- **Design System**: Material 3 with [JFOpenHuninn](https://github.com/justfont/open-huninn-font) (粉圓體)
- **Data Storage**: [Shared Preferences](https://pub.dev/packages/shared_preferences)

## 🚀 快速開始

### 環境需求
- Flutter SDK (建議 ^3.11.0)
- Android Studio / VS Code (安裝 Dart & Flutter 擴充功能)

### 安裝與執行
1. 複製此專案：
   ```bash
   git clone https://github.com/Hamsterowo/NYUST-APP.git
   ```
2. 安裝套件：
   ```bash
   flutter pub get
   ```
3. 啟動 App：
   ```bash
   flutter run
   ```

## 📦 打包發布

為了保護程式碼邏輯，發布正式版本時建議使用以下混淆指令進行打包：

### Android (APK)
```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```

### 參數說明：
- `--obfuscate`: 啟動程式碼混淆，隱藏變數名稱與邏輯。
- `--split-debug-info`: 指定偵錯資訊存儲路徑（用於還原混淆後的錯誤紀錄）。

## 📜 免責聲明 (Disclaimer)

本專案為開發者獨立開發的第三方應用程式，並非由 **國立雲林科技大學 (NYUST)** 官方開發或維護。本 App 透過模擬登錄方式獲取資料，所有使用者帳號密碼僅用於與校方伺服器驗證，開發者不會收集、儲存或洩漏使用者的個人隱私資訊。

## 🤝 貢獻與反饋

如果你有任何建議或發現 Bug，歡迎提交 [Issue](https://github.com/Hamsterowo/NYUST-APP/issues) 或 Pull Request。

---
Made by [Hamster](https://github.com/Hamsterowo)
