import 'package:image_picker/image_picker.dart';

/// Bug 回報與服務條款相關的服務介面（打 App 自己的後端）。
abstract interface class ReportService {
  /// 取得服務條款內容。
  Future<Map<String, dynamic>> getTermsOfService({String? lang});

  /// 送出 Bug 回報，可附帶截圖。
  Future<Map<String, dynamic>> submitBugReport({
    required String description,
    String? contact,
    required String deviceInfo,
    XFile? imageFile,
  });
}
