import '../api_client.dart';
import '../scrapers/absent_scraper.dart';
import 'absent_service.dart';

/// 以 YunTech WebASXASG 網頁為後端的 [AbsentService] 實作。
class NyustAbsentService implements AbsentService {
  final ApiClient _client;
  late final AbsentScraper _scraper;

  NyustAbsentService(this._client) {
    _scraper = AbsentScraper(_client.dio);
  }

  @override
  Future<Map<String, dynamic>> getAbsentRecords({String? semester}) async {
    await _client.ensureInit();
    return _scraper.getAbsentRecords(semester: semester);
  }
}
