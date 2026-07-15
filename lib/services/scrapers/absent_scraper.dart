import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import '../../utils/network_error.dart';
import 'base_scraper.dart';

/// 請假記錄查詢（WebASXASG/StudAbsentApp/DeepQry）。
///
/// 此頁為 ASP.NET WebForms：學年期以 DropDownList（AutoPostBack）切換，
/// 資料在 `GridView1`。作法比照 [ScheduleScraper]：GET 拿到當前學期頁面，
/// 若要看其他學期則帶 `__VIEWSTATE` 等 hidden 欄位做一次 postback。
class AbsentScraper extends BaseScraper {
  AbsentScraper(super.dio);

  static const String absentUrl =
      'https://webapp.yuntech.edu.tw/WebASXASG/StudAbsentApp/DeepQry/StudAbsentAppDeepQry.aspx';

  /// 學年期下拉選單欄位名（value 形如 `114,2`）。
  static const String _semesterField =
      r'ctl00$ContentPlaceHolder1$AcadSemeTypeDropDownList';
  static const String _semesterSelector =
      '#ctl00_ContentPlaceHolder1_AcadSemeTypeDropDownList option';
  static const String _gridSelector = '#ctl00_ContentPlaceHolder1_GridView1 tr';

  /// 取得請假記錄。[semester] 為學年期代碼（如 `114,2`）；null 或當前學期時
  /// 直接解析當前頁面，否則以 postback 切換。
  Future<Map<String, dynamic>> getAbsentRecords({String? semester}) async {
    try {
      var response = await getWithRedirects(
        absentUrl,
        options: Options(headers: commonHeaders),
      );

      var document = parseHtml(response.data);

      // WebASXASG 是獨立的 ASP.NET App：第一次直接開 DeepQry 深層頁時，若該
      // App 自己的 session 尚未建立，SSO 交握會把我們彈回其首頁
      // （StudAbsentAppQry.aspx），該頁沒有「學年期」下拉，會誤判為過期。此時
      // App session 其實已經建立，重新打一次同一個網址就會正確落在深層頁
      // （比照 [AppWebViewScreen] 的 `_maybeReachIntendedPage`）。只重試一次，
      // 避免真的過期時無限重試。
      if (document.querySelectorAll(_semesterSelector).isEmpty) {
        response = await getWithRedirects(
          absentUrl,
          options: Options(headers: {...commonHeaders, 'Referer': absentUrl}),
        );
        document = parseHtml(response.data);
      }

      // Session 判斷：正常頁面一定有「學年期」下拉；被導回登入頁時則沒有。
      // 注意：不能用 `contains('Login.aspx')` 判斷——此頁頁首選單本來就含多個
      // 指向各子系統登入頁的連結，正常登入時也會命中而誤判為過期。
      if (document.querySelectorAll(_semesterSelector).isEmpty) {
        return {
          'status': 'session_expired',
          'message': 'Session expired, please login again',
        };
      }

      final semesters = _parseSemesters(document);
      final currentSemester = _selectedSemester(document);

      if (semester != null &&
          semester.isNotEmpty &&
          semester != currentSemester) {
        final switched = await _postbackSemester(document, semester);
        if (switched != null) document = switched;
      }

      final selected = (semester != null && semester.isNotEmpty)
          ? semester
          : currentSemester;
      final records = _parseRecords(document, selected);

      if (kDebugMode) {
        print('AbsentScraper: parsed ${records.length} records for $selected');
      }

      return {
        'status': 'success',
        'data': {
          'records': records,
          'semesters': semesters,
          'currentSemester': currentSemester,
        },
      };
    } catch (e) {
      // 先判離線再歸類其他錯誤；message 僅供除錯 log，不進 UI。
      if (isNetworkError(e)) {
        return {
          'status': 'network_error',
          'message': 'Network error fetching absent records: $e',
        };
      }
      return {
        'status': 'error',
        'message': 'Failed to fetch absent records: $e',
      };
    }
  }

  List<Map<String, String>> _parseSemesters(dom.Document document) {
    final result = <Map<String, String>>[];
    for (final o in document.querySelectorAll(_semesterSelector)) {
      final value = o.attributes['value']?.trim() ?? '';
      if (value.isEmpty) continue; // 略過「請選擇學年期」
      result.add({'value': value, 'label': o.text.trim()});
    }
    return result;
  }

  String _selectedSemester(dom.Document document) {
    final selected = document.querySelector(
      '#ctl00_ContentPlaceHolder1_AcadSemeTypeDropDownList option[selected]',
    );
    final value = selected?.attributes['value']?.trim() ?? '';
    if (value.isNotEmpty) return value;
    // 沒有明確選中 → 取第一個有效選項。
    for (final o in document.querySelectorAll(_semesterSelector)) {
      final v = o.attributes['value']?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Future<dom.Document?> _postbackSemester(
    dom.Document document,
    String semester,
  ) async {
    try {
      final form = <String, String>{};
      for (final input in document.querySelectorAll('input[type="hidden"]')) {
        final name = input.attributes['name'];
        if (name != null && name.isNotEmpty) {
          form[name] = input.attributes['value'] ?? '';
        }
      }
      form['__EVENTTARGET'] = _semesterField;
      form['__EVENTARGUMENT'] = '';
      form[_semesterField] = semester;

      final res = await dio.post(
        absentUrl,
        data: form,
        options: Options(
          headers: {...commonHeaders, 'Referer': absentUrl},
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      return parseHtml(res.data);
    } catch (e) {
      if (kDebugMode) print('AbsentScraper: postback failed: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _parseRecords(
    dom.Document document,
    String semesterCode,
  ) {
    // 學年期代碼形如 `114,2`。
    final parts = semesterCode.split(',');
    final year = parts.isNotEmpty ? parts[0].trim() : '';
    final sem = parts.length > 1 ? parts[1].trim() : '';

    final records = <Map<String, dynamic>>[];
    for (final row in document.querySelectorAll(_gridSelector)) {
      // 資料列一定有簽核狀態欄；表頭（th）與空列則沒有。
      if (_bySuffix(row, '_AUDIT_FLAG_Label') == null) continue;

      records.add({
        'formNo': row.querySelector('td')?.text.trim() ?? '',
        'proofDoc': _text(row, '_FileMessage'),
        'year': year,
        'semester': sem,
        'formType': _text(row, '_FORM_TYPE_NAME'),
        'leaveType': _text(row, '_TYPE_CODE_MAIN_NAME'),
        'subType': _text(row, '_TYPE_CODE_MIDDLE_NAME'),
        'startDate': _text(row, '_START_DATELabel'),
        'startTime': _text(row, '_START_TIMELabel'),
        'startSection': _text(row, '_S_SECTIONLabel'),
        'endDate': _text(row, '_END_DATELabel'),
        'endTime': _text(row, '_END_TIMELabel'),
        'endSection': _text(row, '_E_SECTIONLabel'),
        'hours': _text(row, '_REPU_NUMLabel'),
        'status': _text(row, '_AUDIT_FLAG_Label'),
      });
    }
    return records;
  }

  /// 取列內 id 以 [suffix] 結尾的元素文字（找不到回空字串）。
  String _text(dom.Element row, String suffix) =>
      _bySuffix(row, suffix)?.text.trim() ?? '';

  dom.Element? _bySuffix(dom.Element row, String suffix) {
    for (final el in row.querySelectorAll('[id]')) {
      if (el.id.endsWith(suffix)) return el;
    }
    return null;
  }
}
