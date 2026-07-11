/// 認證相關的服務介面：SSO 登入初始化、登入、取得使用者資訊、登出。
abstract interface class AuthService {
  /// 初始化登入流程（取得驗證碼圖片與 verification token）。
  Future<Map<String, dynamic>> loginInit();

  /// 以帳號密碼與驗證碼登入。
  ///
  /// 若帳號啟用二步驟驗證（TOTP），回傳的 Map 會含 `mfaRequired: true` 與
  /// 一個新的 `verificationToken`，需再呼叫 [submitTotp] 完成登入。
  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String captcha,
    String verificationToken,
  );

  /// 提交二步驟驗證（TOTP）6 碼驗證碼，完成登入。
  Future<Map<String, dynamic>> submitTotp(
    String code,
    String verificationToken,
  );

  /// 變更 SSO 密碼（需已登入）。回傳 `{success, message}`。
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  );

  /// 取得目前登入使用者的資訊。
  Future<Map<String, dynamic>> getUserInfo();

  /// 登出（清除 Cookies）。
  Future<void> logout();
}
