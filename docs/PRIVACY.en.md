---
title: YunTool Privacy Policy
sourceUrl: https://github.com/Hamsterowo/NYUST-APP
version: 2026-07-09
lastUpdated: July 9, 2026
---

# YunTool Privacy Policy

YunTool ("the app") is an independently developed third-party mobile application. It has no partnership, commission, affiliation, or endorsement relationship with the Computer Center or any official unit of National Yunlin University of Science and Technology ("YunTech"). This policy explains how the app collects, processes, uses, and protects your personal data.

## 1. Scope

This policy applies to the collection, processing, use, and protection of personal data when you use the app. It does not apply to other systems or websites linked from the app (including the various services of YunTech's Single Sign-On portal). When you access those services through the app, the privacy policy of each such service applies.

## 2. How Personal Data Is Collected, Processed, and Used

### (a) YunTech account and password

Your student ID and password are used solely to authenticate you with YunTech's official systems on your behalf. The app uses two official authentication channels: the web SSO portal (which requires an image captcha), and the dedicated endpoint used by the official mobile app (MobileAppService, captcha-free, powering certain features such as the Enrollment Certificate).

- By default the password exists only in memory during login and is released after authentication; **it is never written to device storage or saved on any server** (and it is hashed before being sent).
- Credentials are sent directly and only to YunTech's official server (webapp.yuntech.edu.tw), never to any third party.
- After a successful login, the credentials issued by YunTech (the web session cookie and the mobile endpoint's Bearer access token) are stored encrypted in your device's secure storage for automatic login, background grade checks, and features like the Enrollment Certificate; they are cleared when you log out.
- **Remember password (optional, off by default)**: if you choose "Remember password" on the login screen or in the "App Credential" settings, the app stores a **one-way hash of your password (SHA-256, not the plaintext)** in your device's secure storage, used only to automatically re-obtain the mobile endpoint's access token when it expires, so features like the Enrollment Certificate don't require re-entering your password. This hash **cannot be reversed to your original password and cannot be used for the web login**; it stays only on your device and is never uploaded. You can turn "Remember password" off in settings or log out at any time to clear the stored hash.

### (b) Academic and personal data

After authentication, the app retrieves academic information such as your timetable, grades, graduation credits, and basic profile from YunTech's system, and caches it only on your device to reduce repeated network requests: academic data (timetable, grades, graduation audit) is kept in a local database, while your basic profile and the grade-comparison snapshot are stored encrypted in secure storage. **None of this data is ever sent anywhere off your device.**

### (c) Background grade-update notifications

The app offers a grade-update reminder that runs a background task querying YunTech's system directly for the latest grades, compares them with the copy cached on your device, and fires a **purely local notification** if something changed (no push server, no Firebase or other third-party push service). The entire comparison and notification flow happens on your device; no data leaves it as a result.

### (d) Issue reporting

The app's "Report an Issue" feature does not collect or upload any data in the background. Tapping it simply directs you to contact the developers via email or the Discord community; any description, contact details, or screenshots you choose to provide are composed and sent by you in your own message. The app neither handles nor stores that content.

### (e) Preferences

App settings (display preferences, language, etc.) are stored locally on your device.

## 3. Data Protection

Your academic records, basic profile, session credentials, and preferences are stored only on your device. Your **plaintext password is never persisted**; only when you actively choose "Remember password" is an irreversible hash of it stored in secure storage, used solely to auto-renew the mobile endpoint credential, and it can be cleared at any time by turning the option off or logging out. The app has no developer-operated backend server and does not collect, store, or transmit any of your personal or academic data. You can delete everything stored on your device at any time by logging out, clearing the app's data, or uninstalling it.

## 4. Sharing Personal Data With Third Parties

The app will never provide, exchange, rent, or sell any of your personal data to any individual, group, private enterprise, or government agency. Official release builds (Android) integrate Google Firebase Analytics (anonymous usage statistics) and Crashlytics (crash reporting) to understand feature usage and diagnose errors; these services collect anonymous technical information such as usage events, device model, OS version, and crash stack traces — never your student ID, password, grades, or other personal/academic data. That data is processed by Google under its own privacy policy. Beyond this, the app integrates no other third-party analytics or push services.

## 5. External Links

The app links to YunTech services and other external websites. This policy does not apply to those linked sites; please refer to each site's own privacy policy.

## 6. Exercising Your Data Rights

Under the Personal Data Protection Act, you may exercise rights to inquire, review, supplement, correct, stop collection/processing/use, or delete your data. Since your account, academic, and preference data are stored only on your device, you may exercise these rights at any time by clearing the app's data or uninstalling it.

## 7. Note on YunTech's Systems

The app acts only as a mobile client proxy for YunTech's official systems. The accuracy of all timetable, grade, and graduation-credit data is governed by what YunTech's official system shows. The app cannot control, and does not represent, how YunTech processes, stores, or uses your data; your data on YunTech's servers is governed by YunTech's own privacy policy and the Personal Data Protection Act. Changes to YunTech's systems may temporarily break some features; the developers maintain the app on a best-effort basis and do not guarantee availability or real-time accuracy.

## 8. Children's Privacy

The app is designed for university students and does not specifically target children under 13.

## 9. Changes to This Policy

This policy may be revised as needed. Revised content will be posted within the app, and the "last updated" date at the top will be updated accordingly.

## 10. Contact

For any questions, feature suggestions, or security issues, please use the app's "Report an Issue" feature (email or the Discord community), or reach the developers via [GitHub Issues](https://github.com/Hamsterowo/NYUST-APP/issues).
