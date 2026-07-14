import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../utils/network_error.dart';
import 'base_scraper.dart';

/// 處理學校 SSO 登入邏輯的類別
class SsoScraper extends BaseScraper {
  SsoScraper(super.dio);

  static const String loginPageUrl =
      'https://webapp.yuntech.edu.tw/YunTechSSO/Account/Login';
  static const String captchaUrl =
      'https://webapp.yuntech.edu.tw/YunTechSSO/Captcha/Number';

  /// 開啟二步驟驗證（TOTP / Google Authenticator）的帳號，登入後會被導向這頁。
  static const String authenticatorUrl =
      'https://webapp.yuntech.edu.tw/YunTechSSO/Account/Authenticator';

  /// TOTP 驗證碼的提交端點（Authenticator 表單的 action）。
  static const String validateTotpUrl =
      'https://webapp.yuntech.edu.tw/YunTechSSO/Account/ValidateGoogleAuthCode';

  /// 變更密碼頁（GET 取表單/token、POST 送出皆為此網址）。
  static const String changePasswordUrl =
      'https://webapp.yuntech.edu.tw/YunTechSSO/Account/ChangePassword';

  /// 初始化登入：獲取 VerificationToken 與驗證碼圖片
  Future<Map<String, dynamic>> loginInit() async {
    try {
      if (kDebugMode)
        print('SsoScraper: Fetching login page from $loginPageUrl');
      final response = await dio.get(
        loginPageUrl,
        options: Options(
          headers: {
            ...commonHeaders,
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Upgrade-Insecure-Requests': '1',
            'Cache-Control': 'max-age=0',
          },
        ),
      );

      final document = parseHtml(response.data);

      final tokenElement = document.querySelector(
        'input[name="__RequestVerificationToken"]',
      );
      final token = getAttribute(tokenElement, 'value');

      if (token.isEmpty) {
        throw Exception('無法獲取登入驗證碼 (Token not found)');
      }

      if (kDebugMode) print('SsoScraper: Fetching captcha image...');
      final captchaRes = await dio.get(
        captchaUrl,
        options: Options(
          headers: {...commonHeaders, 'Referer': loginPageUrl},
          responseType: ResponseType.bytes,
        ),
      );

      final contentType = captchaRes.headers.value('content-type') ?? '';
      String base64Image = '';

      if (contentType.contains('image/')) {
        base64Image = base64Encode(captchaRes.data);
      } else {
        base64Image = utf8.decode(captchaRes.data);
      }

      return {
        'success': true,
        'verificationToken': token,
        'captchaImage': 'data:image/png;base64,$base64Image',
      };
    } catch (e) {
      if (kDebugMode) print('SsoScraper Error: $e');
      // 先判離線再歸類其他錯誤；message 僅供除錯 log，不進 UI。
      if (isNetworkError(e)) {
        return {
          'success': false,
          'status': 'network_error',
          'message': 'Network error during login init: $e',
        };
      }
      return {
        'success': false,
        'status': 'error',
        'message': 'Login init failed: $e',
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
      final formData = {
        '__RequestVerificationToken': verificationToken,
        'pLoginName': username,
        'pLoginPassword': password,
        'pSecretString': captcha.toUpperCase(),
        'pRememberMe': rememberMe.toString(),
        'RedirectTo': '',
        'ReturnUrl': '/YunTechSSO/',
      };

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

      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value('location');
        if (kDebugMode) print('SsoScraper: Login redirecting to $location');

        // 開啟二步驟驗證（TOTP）的帳號：帳密／驗證碼正確後不會直接完成登入，
        // 而是被導向 Authenticator 頁要求輸入 6 碼驗證碼。抓該頁的新
        // __RequestVerificationToken 交給上層，讓 UI 收集 TOTP 後再提交。
        if (location != null && location.contains('Account/Authenticator')) {
          return await _fetchTotpChallenge(location);
        }

        if (location != null) {
          final redirectUrl = location.startsWith('http')
              ? location
              : 'https://webapp.yuntech.edu.tw$location';

          await dio.get(
            redirectUrl,
            options: Options(headers: commonHeaders, followRedirects: true),
          );
        }

        return {'success': true, 'message': '登入成功'};
      }

      final document = parseHtml(response.data);
      String errorMsg = '登入失敗，請檢查帳號密碼與驗證碼';

      final validationSum = document
          .querySelector('.validation-summary-errors')
          ?.text
          .trim();
      if (validationSum != null && validationSum.isNotEmpty) {
        errorMsg = validationSum;
      }

      final fieldError = document
          .querySelector('.field-validation-error')
          ?.text
          .trim();
      if (fieldError != null && fieldError.isNotEmpty) {
        errorMsg += ' ($fieldError)';
      }

      // 伺服器有回應且解析到驗證錯誤 → 憑證被明確拒絕（帳密/驗證碼錯）。
      return {'success': false, 'status': 'rejected', 'message': errorMsg};
    } catch (e) {
      if (isNetworkError(e)) {
        return {
          'success': false,
          'status': 'network_error',
          'message': 'Network error during login: $e',
        };
      }
      return {
        'success': false,
        'status': 'error',
        'message': 'Login request failed: $e',
      };
    }
  }

  /// 變更 SSO 密碼。需在已登入（有 `.YunTechSSO` cookie）狀態下呼叫。
  ///
  /// 流程與 [login] 相同：先 GET 變更密碼頁取 __RequestVerificationToken，
  /// 再 POST `OldPassword`/`pNewPassword`/`pConfirmPassword`。成功回 302 轉址。
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final pageRes = await getWithRedirects(
        changePasswordUrl,
        options: Options(headers: {...commonHeaders}),
      );
      final pageDoc = parseHtml(pageRes.data);

      // 已登出會被導向登入頁 → 無變更密碼表單。
      final tokenElement = pageDoc.querySelector(
        '#ApplyForm input[name="__RequestVerificationToken"], '
        'input[name="__RequestVerificationToken"]',
      );
      final token = getAttribute(tokenElement, 'value');
      if (token.isEmpty) {
        return {
          'success': false,
          'status': 'error',
          'message': '無法取得變更密碼表單，請重新登入',
        };
      }

      final formData = {
        '__RequestVerificationToken': token,
        'OldPassword': oldPassword,
        'pNewPassword': newPassword,
        'pConfirmPassword': newPassword,
      };

      final response = await dio.post(
        changePasswordUrl,
        data: FormData.fromMap(formData),
        options: Options(
          headers: {
            ...commonHeaders,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': changePasswordUrl,
          },
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 302 || response.statusCode == 301) {
        return {'success': true, 'message': '密碼變更成功'};
      }

      // 停在原頁：解析驗證錯誤（舊密碼錯誤、格式不符等）。
      final document = parseHtml(response.data);
      String errorMsg = '密碼變更失敗';
      final validationSum = document
          .querySelector('.validation-summary-errors')
          ?.text
          .trim();
      final fieldError = document
          .querySelector('.field-validation-error')
          ?.text
          .trim();
      if (validationSum != null && validationSum.isNotEmpty) {
        errorMsg = validationSum;
      } else if (fieldError != null && fieldError.isNotEmpty) {
        errorMsg = fieldError;
      }
      // 伺服器有回應且解析到驗證錯誤（舊密碼錯誤、格式不符等）。
      return {'success': false, 'status': 'rejected', 'message': errorMsg};
    } catch (e) {
      if (isNetworkError(e)) {
        return {
          'success': false,
          'status': 'network_error',
          'message': 'Network error during password change: $e',
        };
      }
      return {
        'success': false,
        'status': 'error',
        'message': 'Password change request failed: $e',
      };
    }
  }

  /// 抓 Authenticator（TOTP）頁面並取出新的 __RequestVerificationToken。
  /// 回傳 `mfaRequired: true`，讓上層改為收集 6 碼驗證碼再呼叫 [submitTotp]。
  Future<Map<String, dynamic>> _fetchTotpChallenge(String location) async {
    final url = location.startsWith('http')
        ? location
        : 'https://webapp.yuntech.edu.tw$location';
    final res = await dio.get(
      url,
      options: Options(
        headers: {...commonHeaders, 'Referer': loginPageUrl},
        followRedirects: true,
      ),
    );

    final document = parseHtml(res.data);
    final tokenElement = document.querySelector(
      'input[name="__RequestVerificationToken"]',
    );
    final token = getAttribute(tokenElement, 'value');

    if (token.isEmpty) {
      // 拿不到 token 就無法提交 TOTP；回報錯誤讓使用者重登。
      return {'success': false, 'status': 'error', 'message': '無法取得二步驟驗證表單'};
    }

    return {'success': false, 'mfaRequired': true, 'verificationToken': token};
  }

  /// 提交 TOTP（Google Authenticator）6 碼驗證碼。
  ///
  /// [verificationToken] 是 [_fetchTotpChallenge] 從 Authenticator 頁取得的
  /// 新 token。驗證碼正確 → 302 完成登入；錯誤 → 學校會把使用者踢回登入頁
  /// （整個 session 作廢），此時回傳 `success: false` 並附 `restart: true`，
  /// 由上層引導重新登入（含重新取得驗證碼）。
  Future<Map<String, dynamic>> submitTotp({
    required String code,
    required String verificationToken,
  }) async {
    try {
      final formData = {
        '__RequestVerificationToken': verificationToken,
        'ValidateCode': code.trim(),
        // Authenticator 表單的隱藏欄位（外部驗證整合用，正常流程皆為空）。
        'auth_appid': '',
        'auth_token': '',
        'auth_sig': '',
        'auth_ts': '',
        'auth_nonce': '',
        'auth_version': '',
        'UrlQuery': '',
      };

      final response = await dio.post(
        validateTotpUrl,
        data: FormData.fromMap(formData),
        options: Options(
          headers: {
            ...commonHeaders,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': authenticatorUrl,
          },
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value('location') ?? '';
        if (kDebugMode) print('SsoScraper: TOTP redirecting to $location');

        // 驗證碼錯誤 → 被導回登入頁，session 已失效，需重新登入。
        if (location.contains('Account/Login')) {
          return {
            'success': false,
            'status': 'rejected',
            'restart': true,
            'message': '二步驟驗證碼錯誤',
          };
        }

        final redirectUrl = location.startsWith('http')
            ? location
            : 'https://webapp.yuntech.edu.tw$location';
        await dio.get(
          redirectUrl,
          options: Options(headers: commonHeaders, followRedirects: true),
        );
        return {'success': true, 'message': '登入成功'};
      }

      // 沒有轉址（停留在 Authenticator 頁）視為驗證失敗，可再試一次。
      return {'success': false, 'status': 'rejected', 'message': '二步驟驗證碼錯誤'};
    } catch (e) {
      if (isNetworkError(e)) {
        return {
          'success': false,
          'status': 'network_error',
          'message': 'Network error during TOTP validation: $e',
        };
      }
      return {
        'success': false,
        'status': 'error',
        'message': 'TOTP validation request failed: $e',
      };
    }
  }
}
