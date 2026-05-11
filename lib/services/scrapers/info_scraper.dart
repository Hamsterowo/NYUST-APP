import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'base_scraper.dart';

/// 處理個人資訊爬取的類別
class InfoScraper extends BaseScraper {
  InfoScraper(super.dio);

  static const String infoPageUrl =
      'https://webapp.yuntech.edu.tw/eStudent/EStud/Default.aspx';

  /// 獲取使用者基本資料
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      if (kDebugMode) print('InfoScraper: Fetching user info from $infoPageUrl');

      // 仿照舊 API，直接請求 Default.aspx
      final response = await getWithRedirects(
        infoPageUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            // 舊 API 似乎沒有傳 Referer，或者是由 fetch 自動處理
          },
        ),
      );

      if (kDebugMode) {
        print('InfoScraper: Response Status: ${response.statusCode}');
      }

      var document = parseHtml(response.data);
      if (kDebugMode) print('InfoScraper: Page Title: ${document.querySelector('title')?.text.trim()}');
      
      // 檢查是否拿到了真正的內容頁 (Default.aspx 其實是 Frameset，但 getWithRedirects 會跳轉到內容)
      // 如果內容不對，嘗試抓取 StudInfo.aspx
      if (response.data.toString().contains('ctl00_showName') == false && 
          response.data.toString().contains('姓名') == false) {
        if (kDebugMode) print('InfoScraper: Content seems missing, trying fallback to StudInfo.aspx...');
        final studInfoRes = await getWithRedirects(
          'https://webapp.yuntech.edu.tw/eStudent/EStud/StudInfo.aspx',
          options: Options(headers: commonHeaders),
        );
        document = parseHtml(studInfoRes.data);
      }

      final userInfo = <String, String>{};

      final fieldsToExtract = [
        '入學年制', '學號', '姓名', '輔系/雙主修', '特殊身分', '系(所)別', '班級', '性別', '教育學程', '學程'
      ];

      for (var field in fieldsToExtract) {
        bool found = false;
        final elements = document.querySelectorAll('span, th, td, label, div');

        for (var el in elements) {
          final text = el.text.trim().replaceAll(RegExp(r'[\s：:]'), '');
          final target = field.replaceAll(RegExp(r'[\s：:]'), '');

          if (text == target) {
            String value = '';
            if (el.localName == 'th' || el.localName == 'td') {
              value = el.nextElementSibling?.text.trim() ?? '';
            } else {
              final nextSib = el.nextElementSibling;
              if (nextSib != null && nextSib.text.trim().isNotEmpty) {
                value = nextSib.text.trim();
              } else {
                dom.Element? parentCell = el.parent;
                while (parentCell != null && parentCell.localName != 'td' && parentCell.localName != 'th') {
                  parentCell = parentCell.parent;
                }
                if (parentCell != null) {
                  value = parentCell.nextElementSibling?.text.trim() ?? '';
                }
              }
            }

            if (value.isNotEmpty) {
              userInfo[field] = value;
              found = true;
              break;
            }
          }
        }
        if (!found) userInfo[field] = '';
      }

      userInfo['姓名'] = userInfo['姓名'] ?? '';
      
      if (userInfo['姓名']!.isEmpty) {
        userInfo['姓名'] = document.querySelector('#ctl00_showName')?.text.trim() ?? 
                         document.querySelector('#ctl00_showUser')?.text.trim() ?? 
                         document.querySelector('span[id*="showName"]')?.text.trim() ?? 
                         '';
      }

      userInfo['name'] = userInfo['姓名']!;
      userInfo['department'] = userInfo['系(所)別'] ?? '';

      if (userInfo['name']!.isEmpty) {
        final allTexts = document.querySelectorAll('span, td, div').map((e) => e.text.trim()).toList();
        for (var t in allTexts) {
          if (t.contains('歡迎') && t.contains('同學')) {
            userInfo['name'] = t.replaceAll('歡迎', '').replaceAll('同學', '').trim();
            userInfo['姓名'] = userInfo['name']!;
            break;
          }
        }
      }

      if (kDebugMode && userInfo['name']!.isEmpty) {
        print('InfoScraper: CRITICAL - All name extraction strategies failed.');
      }

      if (kDebugMode) print('InfoScraper: Final Extracted info for ${userInfo['name']}');

      return {
        'success': true,
        'user': userInfo,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '獲取個人資訊失敗: $e',
      };
    }
  }
}
