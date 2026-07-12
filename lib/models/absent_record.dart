/// 一筆請假記錄（對應請假記錄查詢頁 GridView 的一列）。
///
/// 資料來源：WebASXASG/StudAbsentApp/DeepQry（僅中文，值維持原文）。
class AbsentRecord {
  final String formNo; // 請假表單編號
  final String proofDoc; // 請假證明文件（紙本/電子…）
  final String year; // 學年（如 114）
  final String semester; // 學期（1/2）
  final String formType; // 請假分類（如 一般請假）
  final String leaveType; // 假別（如 心理調適假）
  final String subType; // 次假別（可能為空）
  final String startDate; // 起始日期（如 115/06/10）
  final String startTime; // 起始時（如 10）
  final String startSection; // 起始節次（如 C）
  final String endDate;
  final String endTime;
  final String endSection;
  final String hours; // 請假時數
  final String status; // 簽核狀態（如 已核可）

  const AbsentRecord({
    required this.formNo,
    required this.proofDoc,
    required this.year,
    required this.semester,
    required this.formType,
    required this.leaveType,
    required this.subType,
    required this.startDate,
    required this.startTime,
    required this.startSection,
    required this.endDate,
    required this.endTime,
    required this.endSection,
    required this.hours,
    required this.status,
  });

  factory AbsentRecord.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString().trim();
    return AbsentRecord(
      formNo: s('formNo'),
      proofDoc: s('proofDoc'),
      year: s('year'),
      semester: s('semester'),
      formType: s('formType'),
      leaveType: s('leaveType'),
      subType: s('subType'),
      startDate: s('startDate'),
      startTime: s('startTime'),
      startSection: s('startSection'),
      endDate: s('endDate'),
      endTime: s('endTime'),
      endSection: s('endSection'),
      hours: s('hours'),
      status: s('status'),
    );
  }

  /// 單一時間端點文字，如「115/06/10 10時 C節」（缺項自動省略）。
  String _endpoint(String date, String time, String section) {
    final parts = <String>[
      if (date.isNotEmpty) date,
      if (time.isNotEmpty) '$time時',
      if (section.isNotEmpty) '$section節',
    ];
    return parts.join(' ');
  }

  /// 起訖時間文字，如「115/06/10 10時 C節 ~ 115/06/10 12時 D節」。
  String get periodRange {
    final start = _endpoint(startDate, startTime, startSection);
    final end = _endpoint(endDate, endTime, endSection);
    if (start.isEmpty) return end;
    if (end.isEmpty || end == start) return start;
    return '$start ~ $end';
  }
}
