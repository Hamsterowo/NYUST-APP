import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'base_scraper.dart';

/// 處理學校 SSO 登入邏輯的類別
class SsoScraper extends BaseScraper {
  SsoScraper(super.dio);

  static const String loginPageUrl =
      'https://webapp.yuntech.edu.tw/YunTechSSO/Account/Login';
  static const String captchaUrl =
      'https://webapp.yuntech.edu.tw/YunTechSSO/Captcha/Number';

  /// 初始化登入：獲取 VerificationToken 與驗證碼圖片
  Future<Map<String, dynamic>> loginInit() async {
    try {
      // 1. 請求登入頁面
      if (kDebugMode) print('SsoScraper: Fetching login page from $loginPageUrl');
      final response = await dio.get(
        loginPageUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Upgrade-Insecure-Requests': '1',
            'Cache-Control': 'max-age=0',
          },
        ),
      );

      if (kDebugMode) {
        print('SsoScraper: Response Status: ${response.statusCode}');
        // 印出前 1000 個字元以便偵錯
        final body = response.data.toString();
        print('SsoScraper: Response Body Preview: ${body.length > 1000 ? body.substring(0, 1000) : body}');
      }

      final document = parseHtml(response.data);

      // 2. 提取 __RequestVerificationToken
      final tokenElement =
          document.querySelector('input[name="__RequestVerificationToken"]');
      final token = getAttribute(tokenElement, 'value');

      if (token.isEmpty) {
        throw Exception('無法獲取登入驗證碼 (Token not found)');
      }

      // 3. 請求驗證碼圖片
      if (kDebugMode) print('SsoScraper: Fetching captcha image...');
      final captchaRes = await dio.get(
        captchaUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Referer': loginPageUrl, // 加入 Referer 避開簡單防護
          },
          responseType: ResponseType.bytes,
        ),
      );

      final contentType = captchaRes.headers.value('content-type') ?? '';
      String base64Image = '';

      if (contentType.contains('image/')) {
        // 二進位圖片轉換為 Base64
        base64Image = base64Encode(captchaRes.data);
      } else {
        // 如果伺服器直接回傳 Base64 字串 (API 原始邏輯中見過)
        base64Image = utf8.decode(captchaRes.data);
      }

      return {
        'success': true,
        'verificationToken': token,
        'captchaImage': 'data:image/png;base64,$base64Image',
      };
    } catch (e) {
      if (kDebugMode) print('SsoScraper Error: $e');
      return {
        'success': false,
        'message': '登入初始化失敗: $e',
      };
    }
  }

  /// 執行登入
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String captcha,
    required String verificationToken,
    bool rememberMe = true,
  }) async {
    try {
      // 準備 Form Data
      final formData = {
        '__RequestVerificationToken': verificationToken,
        'pLoginName': username,
        'pLoginPassword': password,
        'pSecretString': captcha.toUpperCase(),
        'pRememberMe': rememberMe.toString(),
        'RedirectTo': '',
        'ReturnUrl': '/YunTechSSO/',
      };

      // 模擬原 API 的 POST 請求
      // 注意：此處需要關閉 followRedirects 以捕捉 302
      final response = await dio.post(
        loginPageUrl,
        data: FormData.fromMap(formData),
        options: Options(
          headers: {
            ...commonHeaders,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': loginPageUrl,
          },
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      // 檢查是否跳轉 (代表登入成功)
      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value('location');
        if (kDebugMode) print('SsoScraper: Login successful, redirecting to $location');
        
        // 重要：必須實際請求導向位址，才能讓伺服器寫入完整的 Session Cookies
        if (location != null) {
          final redirectUrl = location.startsWith('http') 
              ? location 
              : 'https://webapp.yuntech.edu.tw$location';
          
          await dio.get(
            redirectUrl, 
            options: Options(
              headers: commonHeaders,
              followRedirects: true,
            )
          );
        }

        return {
          'success': true,
          'message': '登入成功',
        };
      }

      // 登入失敗：解析錯誤訊息
      final document = parseHtml(response.data);
      String errorMsg = '登入失敗，請檢查帳號密碼與驗證碼';

      final validationSum =
          document.querySelector('.validation-summary-errors')?.text.trim();
      if (validationSum != null && validationSum.isNotEmpty) {
        errorMsg = validationSum;
      }

      final fieldError =
          document.querySelector('.field-validation-error')?.text.trim();
      if (fieldError != null && fieldError.isNotEmpty) {
        errorMsg += ' ($fieldError)';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '登入請求發生錯誤: $e',
      };
    }
  }
}
