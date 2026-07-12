import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/absent_record.dart';
import '../providers/providers.dart';
import '../services/scrapers/absent_scraper.dart';
import '../widgets/custom_app_bar.dart';
import 'web_view_screen.dart';

/// 請假記錄查詢畫面。
///
/// 資料來源為 WebASXASG 請假頁（僅中文），採即時抓取（無 Drift 快取）：
/// 進頁抓當前學年期，可用上方下拉切換其他學年期（scraper 內做 postback）。
class AbsentScreen extends ConsumerStatefulWidget {
  const AbsentScreen({super.key});

  @override
  ConsumerState<AbsentScreen> createState() => _AbsentScreenState();
}

class _AbsentScreenState extends ConsumerState<AbsentScreen> {
  bool _loading = true;
  bool _failed = false;
  List<AbsentRecord> _records = const [];
  List<Map<String, String>> _semesters = const [];
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch({String? semester}) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final api = ref.read(authProvider).api;
      final res = await api.getAbsentRecords(semester: semester);
      if (!mounted) return;
      if (res['status'] == 'success') {
        final data = res['data'] as Map<String, dynamic>;
        final rawRecords = (data['records'] as List?) ?? const [];
        final rawSemesters = (data['semesters'] as List?) ?? const [];
        setState(() {
          _records = rawRecords
              .map((e) => AbsentRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _semesters = rawSemesters
              .map((e) => Map<String, String>.from(e))
              .toList();
          _selectedSemester =
              semester ??
              (data['currentSemester'] as String?) ??
              _selectedSemester;
          _loading = false;
        });
      } else {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.infoAbsentTitle,
        onRefresh: _loading ? null : () => _fetch(semester: _selectedSemester),
        isLoading: _loading,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: l10n.courseOpenInBrowser,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AppWebViewScreen(url: AbsentScraper.absentUrl),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_visibleSemesters.length > 1) _buildSemesterBar(),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  /// 入學學年：取自登入使用者的學號。雲科學號格式為
  /// `字母 + 入學學年(3碼) + 系所流水號`（如 B11417018 → 114）。
  int? _enrollmentYear() {
    final info = ref.read(authProvider).user?['user'];
    final sid = (info is Map ? (info['學號'] ?? info['id']) : null)?.toString();
    final digits = RegExp(r'\d+').firstMatch(sid ?? '')?.group(0) ?? '';
    if (digits.length >= 3) return int.tryParse(digits.substring(0, 3));
    return null;
  }

  /// 過濾掉入學年以前的學年期（判斷不出入學年時，全部顯示）。
  List<Map<String, String>> get _visibleSemesters {
    final enroll = _enrollmentYear();
    if (enroll == null) return _semesters;
    return _semesters.where((s) {
      final year = int.tryParse((s['value'] ?? '').split(',').first.trim());
      return year == null || year >= enroll;
    }).toList();
  }

  Widget _buildSemesterBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(Icons.event_note_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedSemester,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in _visibleSemesters)
                  DropdownMenuItem(
                    value: s['value'],
                    child: Text(s['label'] ?? s['value'] ?? ''),
                  ),
              ],
              onChanged: _loading
                  ? null
                  : (v) {
                      if (v == null || v == _selectedSemester) return;
                      _fetch(semester: v);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.absentLoadFailed,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => _fetch(semester: _selectedSemester),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.absentEmpty,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildCard(_records[i], l10n),
    );
  }

  Widget _buildCard(AbsentRecord r, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(r.status, colorScheme);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.leaveType.isNotEmpty ? r.leaveType : r.formType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (r.formType.isNotEmpty && r.leaveType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.formType,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (r.status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.schedule_outlined, r.periodRange, colorScheme),
          if (r.hours.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(
              Icons.timelapse_outlined,
              l10n.absentHours(r.hours),
              colorScheme,
            ),
          ],
          if (r.proofDoc.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.description_outlined, r.proofDoc, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    if (status.contains('核可') || status.contains('通過')) {
      return const Color(0xFF16A34A); // green
    }
    if (status.contains('審核') ||
        status.contains('簽核') ||
        status.contains('中')) {
      return const Color(0xFFD97706); // amber
    }
    if (status.contains('退') || status.contains('不') || status.contains('駁')) {
      return colorScheme.error;
    }
    return colorScheme.onSurfaceVariant;
  }
}
