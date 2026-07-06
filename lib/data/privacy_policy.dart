/// 本地隱私權政策內容（完全內嵌、無需連網）。
///
/// 內容以中英雙語提供，依語系選取。[kPrivacyPolicyVersion] 為與語系無關的
/// 版本鍵：使用者同意後會存下此值，App 啟動時比對；**內容有實質變更時請更新
/// 此日期**，以觸發重新同意的彈窗流程。
library;

/// 隱私權政策版本鍵（與顯示語系無關，用於同意狀態比對）。
const String kPrivacyPolicyVersion = '2026-07-05';

/// 單一內容區塊：標題或段落。
class PolicyBlock {
  final bool isHeader;
  final String text;

  const PolicyBlock.header(this.text) : isHeader = true;
  const PolicyBlock.paragraph(this.text) : isHeader = false;
}

/// 一份隱私權政策：版本鍵 + 內容區塊。
class PrivacyPolicy {
  final String lastUpdated;
  final List<PolicyBlock> blocks;

  const PrivacyPolicy({required this.lastUpdated, required this.blocks});
}

/// 依語系取得對應的本地隱私權政策。
PrivacyPolicy privacyPolicyFor(String languageCode) =>
    languageCode == 'en' ? _privacyPolicyEn : _privacyPolicyZh;

const PrivacyPolicy _privacyPolicyZh = PrivacyPolicy(
  lastUpdated: kPrivacyPolicyVersion,
  blocks: [
    PolicyBlock.paragraph(
      '雲科工具箱（以下簡稱「雲工具」、「本應用程式」）為第三方獨立開發的行動應用程式，'
      '與國立雲林科技大學（以下簡稱「雲科大」）資訊中心及官方單位無任何合作、委託、隸屬或背書關係。'
      '本政策說明本應用程式如何蒐集、處理、利用及保護您的個人資料。',
    ),
    PolicyBlock.header('一、適用範圍'),
    PolicyBlock.paragraph(
      '本政策適用於您使用本應用程式時所涉及的個人資料蒐集、處理、利用與保護，'
      '不適用於本應用程式所連結的其他系統或網站（包括雲科大單一入口服務網各項服務系統）。'
      '當您透過本應用程式存取前述服務時，需遵守並適用該服務自身的隱私權政策。',
    ),
    PolicyBlock.header('二、個人資料的蒐集、處理及利用方式'),
    PolicyBlock.paragraph(
      '（一）雲科大帳號密碼\n'
      '您的學號與密碼僅用於代您向雲科大官方系統（單一入口服務網）進行身分驗證：密碼僅存在於'
      '登入當下的記憶體中，不會寫入裝置本機儲存空間，也不會保存於任何伺服器；帳號密碼僅直接'
      '傳送至雲科大官方伺服器（webapp.yuntech.edu.tw）進行驗證，絕不會傳送至任何第三方。',
    ),
    PolicyBlock.paragraph(
      '（二）學業與個人資料\n'
      '通過身分驗證後，本應用程式會從雲科大系統取得您的課表、成績、畢業學分及個人基本資料等'
      '學業相關資訊。這些資料會以加密方式快取於您裝置本機的安全儲存區（Secure Storage），'
      '用以減少重複的網路請求，不會被傳送至裝置以外的任何地方。',
    ),
    PolicyBlock.paragraph(
      '（三）成績更新背景通知\n'
      '本應用程式提供成績更新提醒功能，運作方式為：在裝置背景排程中直接向雲科大系統查詢最新成績，'
      '與裝置本機快取的舊資料比對，若有變動則呼叫純本機通知（不經任何推播伺服器、不使用 Firebase '
      '或其他第三方推播服務）。整個比對與通知流程都在您的裝置上完成，沒有任何資料因此離開裝置。',
    ),
    PolicyBlock.paragraph(
      '（四）問題回報\n'
      '本應用程式的「問題回報」功能不會在背景蒐集或上傳任何資料。點選後僅引導您透過電子郵件或 '
      'Discord 社群與開發團隊聯繫，您要提供的問題描述、聯絡方式或截圖，均由您在自己的信件或訊息中'
      '自行決定與送出，本應用程式不經手、不留存這些內容。',
    ),
    PolicyBlock.paragraph(
      '（五）偏好設定\n'
      '應用程式設定（顯示偏好、語言等）儲存於您的裝置本機。',
    ),
    PolicyBlock.header('三、資料之保護'),
    PolicyBlock.paragraph(
      '您的帳號密碼、學業紀錄、偏好設定皆僅儲存於您的裝置本機，帳號密碼且從不落地儲存。'
      '本應用程式沒有任何由開發團隊營運的後端伺服器，不蒐集、不儲存、不傳輸您的任何個人或學業資料。'
      '您可以隨時透過清除應用程式資料或解除安裝，刪除裝置上儲存的所有資料。',
    ),
    PolicyBlock.header('四、與第三方共用個人資料之政策'),
    PolicyBlock.paragraph(
      '本應用程式絕不會提供、交換、出租或出售任何您的個人資料給其他個人、團體、私人企業或公務機關。'
      '本應用程式目前未整合 Firebase Analytics、Crashlytics 或其他第三方分析／推播服務。',
    ),
    PolicyBlock.header('五、對外連結'),
    PolicyBlock.paragraph(
      '本應用程式會連結至雲科大各項服務系統及其他外部網站。該等連結網站不適用本政策，'
      '您應參考各該網站自身的隱私權保護政策。',
    ),
    PolicyBlock.header('六、個人資料權利行使方式'),
    PolicyBlock.paragraph(
      '依據《個人資料保護法》，您可以行使查詢、閱覽、補充、更正、停止蒐集處理利用或刪除等權利。'
      '由於您的帳號、學業與偏好資料皆僅儲存於裝置本機，您可以隨時透過清除應用程式資料或解除安裝'
      '行使上述權利。',
    ),
    PolicyBlock.header('七、關於雲科大系統的實務說明'),
    PolicyBlock.paragraph(
      '本應用程式僅作為雲科大官方系統的行動客戶端代理，所有課表、成績、畢業學分等資料之正確性'
      '均以雲科大官方系統顯示為準。本應用程式無法控制、亦不代表雲科大如何處理、儲存或使用您的資料，'
      '您在雲科大伺服器上的資料受雲科大自身隱私權政策及《個人資料保護法》規範。'
      '若雲科大系統架構有所變更，可能導致本應用程式部分功能暫時無法使用；開發團隊將盡力維護，'
      '但不保證服務隨時可用或資料即時無誤。',
    ),
    PolicyBlock.header('八、兒童隱私'),
    PolicyBlock.paragraph('本應用程式專為大學生設計，不特別針對 13 歲以下兒童。'),
    PolicyBlock.header('九、本政策之修正'),
    PolicyBlock.paragraph('本政策將因應需求隨時修正，修正後的內容將公告於本應用程式內，頂部之修正日期將隨之更新。'),
    PolicyBlock.header('十、聯繫管道'),
    PolicyBlock.paragraph(
      '如對本政策有任何問題、功能建議，或發現安全漏洞，請透過本應用程式內的「回報問題」'
      '（電子郵件或 Discord 社群），或至 GitHub Issues '
      '（https://github.com/Hamsterowo/NYUST-APP/issues）與開發團隊聯繫。',
    ),
  ],
);

const PrivacyPolicy _privacyPolicyEn = PrivacyPolicy(
  lastUpdated: kPrivacyPolicyVersion,
  blocks: [
    PolicyBlock.paragraph(
      'YunTool ("the app") is an independently developed third-party mobile '
      'application. It has no partnership, commission, affiliation, or endorsement '
      'relationship with the Computer Center or any official unit of National '
      'Yunlin University of Science and Technology ("YunTech"). This policy '
      'explains how the app collects, processes, uses, and protects your personal data.',
    ),
    PolicyBlock.header('1. Scope'),
    PolicyBlock.paragraph(
      'This policy applies to the collection, processing, use, and protection of '
      'personal data when you use the app. It does not apply to other systems or '
      'websites linked from the app (including the various services of YunTech\'s '
      'Single Sign-On portal). When you access those services through the app, the '
      'privacy policy of each such service applies.',
    ),
    PolicyBlock.header(
      '2. How Personal Data Is Collected, Processed, and Used',
    ),
    PolicyBlock.paragraph(
      '(a) YunTech account and password\n'
      'Your student ID and password are used solely to authenticate you with '
      'YunTech\'s official system (the SSO portal) on your behalf. The password '
      'exists only in memory during login; it is never written to device storage or '
      'saved on any server. Credentials are sent directly and only to YunTech\'s '
      'official server (webapp.yuntech.edu.tw), never to any third party.',
    ),
    PolicyBlock.paragraph(
      '(b) Academic and personal data\n'
      'After authentication, the app retrieves academic information such as your '
      'timetable, grades, graduation credits, and basic profile from YunTech\'s '
      'system. This data is cached, encrypted, in your device\'s secure storage to '
      'reduce repeated network requests, and is never sent anywhere off your device.',
    ),
    PolicyBlock.paragraph(
      '(c) Background grade-update notifications\n'
      'The app offers a grade-update reminder that runs a background task querying '
      'YunTech\'s system directly for the latest grades, compares them with the copy '
      'cached on your device, and fires a purely local notification if something '
      'changed (no push server, no Firebase or other third-party push service). The '
      'entire comparison and notification flow happens on your device; no data '
      'leaves it as a result.',
    ),
    PolicyBlock.paragraph(
      '(d) Issue reporting\n'
      'The app\'s "Report an Issue" feature does not collect or upload any data in '
      'the background. Tapping it simply directs you to contact the developers via '
      'email or the Discord community; any description, contact details, or '
      'screenshots you choose to provide are composed and sent by you in your own '
      'message. The app neither handles nor stores that content.',
    ),
    PolicyBlock.paragraph(
      '(e) Preferences\n'
      'App settings (display preferences, language, etc.) are stored locally on your device.',
    ),
    PolicyBlock.header('3. Data Protection'),
    PolicyBlock.paragraph(
      'Your credentials, academic records, and preferences are stored only on your '
      'device, and your password is never persisted. The app has no developer-'
      'operated backend server and does not collect, store, or transmit any of your '
      'personal or academic data. You can delete everything stored on your device at '
      'any time by clearing the app\'s data or uninstalling it.',
    ),
    PolicyBlock.header('4. Sharing Personal Data With Third Parties'),
    PolicyBlock.paragraph(
      'The app will never provide, exchange, rent, or sell any of your personal data '
      'to any individual, group, private enterprise, or government agency. The app '
      'currently integrates no Firebase Analytics, Crashlytics, or other third-party '
      'analytics/push services.',
    ),
    PolicyBlock.header('5. External Links'),
    PolicyBlock.paragraph(
      'The app links to YunTech services and other external websites. This policy '
      'does not apply to those linked sites; please refer to each site\'s own '
      'privacy policy.',
    ),
    PolicyBlock.header('6. Exercising Your Data Rights'),
    PolicyBlock.paragraph(
      'Under the Personal Data Protection Act, you may exercise rights to inquire, '
      'review, supplement, correct, stop collection/processing/use, or delete your '
      'data. Since your account, academic, and preference data are stored only on '
      'your device, you may exercise these rights at any time by clearing the app\'s '
      'data or uninstalling it.',
    ),
    PolicyBlock.header('7. Note on YunTech\'s Systems'),
    PolicyBlock.paragraph(
      'The app acts only as a mobile client proxy for YunTech\'s official systems. '
      'The accuracy of all timetable, grade, and graduation-credit data is governed '
      'by what YunTech\'s official system shows. The app cannot control, and does '
      'not represent, how YunTech processes, stores, or uses your data; your data on '
      'YunTech\'s servers is governed by YunTech\'s own privacy policy and the '
      'Personal Data Protection Act. Changes to YunTech\'s systems may temporarily '
      'break some features; the developers maintain the app on a best-effort basis '
      'and do not guarantee availability or real-time accuracy.',
    ),
    PolicyBlock.header('8. Children\'s Privacy'),
    PolicyBlock.paragraph(
      'The app is designed for university students and does not specifically target '
      'children under 13.',
    ),
    PolicyBlock.header('9. Changes to This Policy'),
    PolicyBlock.paragraph(
      'This policy may be revised as needed. Revised content will be posted within '
      'the app, and the "last updated" date at the top will be updated accordingly.',
    ),
    PolicyBlock.header('10. Contact'),
    PolicyBlock.paragraph(
      'For any questions, feature suggestions, or security issues, please use the '
      'app\'s "Report an Issue" feature (email or the Discord community), or reach '
      'the developers via GitHub Issues '
      '(https://github.com/Hamsterowo/NYUST-APP/issues).',
    ),
  ],
);
