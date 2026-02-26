import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NYUST+ 使用者條款',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParagraph(
                  '此使用者條款 ( "此條款" ) 為 NYUST+ APP ( "本應用程式" 、 "本服務" ) 之附註使用條件。',
                  context,
                ),
                _buildSectionTitle('1. 服務說明', context),
                _buildParagraph(
                  '歡迎使用 NYUST+（本應用程式）。本應用程式為第三方專案，並非國立雲林科技大學（YunTech）官方維護之應用程式。本應用程式旨在提供使用者於行動裝置中，使用「國立雲林科技大學單一入口服務網」能夠有較好的操作體驗，並僅作為介面代理與輔助工具。',
                  context,
                ),
                _buildSectionTitle('2. 資料處理與隱私權', context),
                _buildParagraph(
                  '本應用程式承諾不主動收集、不儲存您的任何敏感個人資料。您的帳號、密碼及成績等資訊，皆是直接由您的裝置與「國立雲林科技大學單一入口服務網」進行通訊交換，不會經過第三方資料庫儲存。\n\n'
                  '為維持連線與提供服務，部分連線可能會透過安全的 API 代理層進行轉發，但該代理層僅負責傳遞請求，絕不保留、側錄您的個人機密資訊。'
                  '為提供通知服務，本應用程式可能會儲存您的裝置識別碼，用於接收推播通知。此識別碼用於通知服務，不會對您的資料安全造成影響。\n\n'
                  '本應用程式於您的設備端，採用本地安全儲存區 (Secure Storage) 將您的連線憑證加密保存，防止其他惡意應用程式竊取許可。\n'
                  '為改善應用程式穩定度與操作體驗，本應用程式可能會整合第三方服務收集匿名的日誌或效能數據。這些數據僅用於修復程式錯誤，絕不包含您的帳號密碼、成績等個人機密資訊。',
                  context,
                ),
                _buildSectionTitle('3. 免責聲明', context),
                _buildParagraph(
                  '使用本應用程式所產生之任何操作結果（例如課表查詢、成績查詢等），請以雲科大官方單一入口服務網顯示為準。若因使用本服務而導致任何直接或間接的損害、不便或成績遺漏，本專案開發團隊及貢獻者不負相關法律與賠償責任。\n\n'
                  '另外，本應用程式提供之推播通知服務，可能因使用者的裝置設定、網路狀況或作業系統（如省電模式）而延遲或無法送達。強烈建議使用者仍應主動留意校方之重要公告，本開發團隊不對因通知漏接所生之影響負責。',
                  context,
                ),
                _buildSectionTitle('4. 服務變更與終止', context),
                _buildParagraph(
                  '開發團隊保留隨時修改、暫停或永久終止本應用程式部分或全部服務之權利，且不需事前通知。同時，若校方更改系統架構導致本應用程式無法正常運作，本專案即可能暫停服務直至修復，或可能永久停止維護。',
                  context,
                ),
                _buildSectionTitle('5. 同意條款', context),
                _buildParagraph(
                  '當您登入並開始使用本應用程式時，即代表您已閱讀、瞭解並同意遵守上述所有條款與聲明。如果您不同意本條款之任何部分，請立即停止使用本應用程式，並可隨時登出或刪除本應用程式。',
                  context,
                ),
                _buildSectionTitle('6. 使用者責任規範', context),
                _buildParagraph(
                  '使用者應妥善保管自身的行動裝置與螢幕鎖定密碼。若因裝置遺失或未鎖定，遭他人惡意開啟本應用程式而導致資料外洩，本開發團隊概不負責。此外，使用者不得利用本應用程式進行任何惡意攻擊（如阻斷服務攻擊 DoS）或非法竄改行為。',
                  context,
                ),
                _buildSectionTitle('7. 智慧財產權', context),
                _buildParagraph(
                  '本應用程式介面讀取並顯示之所有校務資料、商標、校徽等相關權利，均歸「國立雲林科技大學」所有。',
                  context,
                ),
                _buildSectionTitle('8. 聯絡我們', context),
                _buildParagraph(
                  '如有任何問題、功能建議或發現安全漏洞，請透過本應用程式內提供之聯絡管道與開發團隊聯繫。',
                  context,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '最後更新日期：2026年02月',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.8,
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
