/// 認證相關的服務介面：SSO 登入初始化、登入、取得使用者資訊、登出。
abstract interface class AuthService {
  /// 初始化登入流程（取得驗證碼圖片與 verification token）。
  Future<Map<String, dynamic>> loginInit();

  /// 以帳號密碼與驗證碼登入。
  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String verificationToken,
  );

  /// 取得目前登入使用者的資訊。
  Future<Map<String, dynamic>> getUserInfo();

  /// 登出（清除 Cookies）。
  Future<void> logout();
}
