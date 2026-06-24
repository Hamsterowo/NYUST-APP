import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';
import '../models/course_detail_model.dart';
import '../models/map_building_model.dart';
import '../services/api_service.dart';
import '../services/course_detail_cache.dart';
import '../utils/top_snack_bar.dart';
import 'map_screen.dart';
import 'web_view_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String year;
  final String semester;
  final String courseNo;
  final String courseName;

  const CourseDetailScreen({
    super.key,
    required this.year,
    required this.semester,
    required this.courseNo,
    required this.courseName,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  CourseDetail? _courseDetail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {

      final response = await CourseDetailCache.getOrFetch(
        widget.year,
        widget.semester,
        widget.courseNo,
        () => _api.getCourseDetail(
          year: widget.year,
          semester: widget.semester,
          courseNo: widget.courseNo,
        ),
      );

      if (!mounted) return;

      if (response != null && response['status'] == 'success') {
        setState(() {
          _courseDetail = CourseDetail.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response?['message'] ?? AppLocalizations.of(context).loadCalendarFailed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context).loadErrorPrefix(e.toString());
        _isLoading = false;
      });
    }
  }

  String _formatContent(String text) {
    if (text.isEmpty) return AppLocalizations.of(context).courseNoData;
    return text.split('\n').map((line) => line.trimLeft()).join('\n').trim();
  }

  String _annotateRequiredType(String rawType) {
    final type = rawType.trim();
    if (type == '必修' || type.toLowerCase() == 'required') {
      return '必修 (Required)';
    } else if (type == '選修' || type.toLowerCase() == 'elective') {
      return '選修 (Elective)';
    } else if (type == '通識' || type.toLowerCase() == 'general education' || type.toLowerCase().contains('general')) {
      return '通識 (General Education)';
    }
    return type;
  }

  List<String> _extractRoomCodes(String timeRoomStr) {
    if (timeRoomStr.isEmpty) return [];
    final parts = timeRoomStr.split(RegExp(r'[\s,，、；;]+'));
    final List<String> rooms = [];
    for (var part in parts) {
      final subParts = part.split('/');
      if (subParts.length >= 2) {
        final room = subParts.last.trim();
        if (room.isNotEmpty && !rooms.contains(room)) {
          rooms.add(room);
        }
      } else {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty &&
            RegExp(r'^[A-Za-z]+').hasMatch(trimmed) &&
            !trimmed.contains('-')) {
          if (!rooms.contains(trimmed)) {
            rooms.add(trimmed);
          }
        }
      }
    }
    return rooms;
  }

  Future<void> _handleNavigateToMap(String roomCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/map_data.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final buildings =
          jsonList.map((item) => MapBuilding.fromJson(item)).toList();

      if (!mounted) return;

      final regExp = RegExp(r'^([A-Za-z]+)(\d*)');
      final match = regExp.firstMatch(roomCode.trim());
      if (match == null) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).courseInvalidRoomCode,
          type: SnackBarType.warning,
        );
        return;
      }

      final String codePrefix = match.group(1)!.toUpperCase();
      bool hasBuilding = false;
      for (var b in buildings) {
        final bIdUpper = b.id.toUpperCase();
        if (bIdUpper.endsWith('-$codePrefix') ||
            b.aliases.any((alias) => alias.toUpperCase() == codePrefix)) {
          hasBuilding = true;
          break;
        }
      }

      if (hasBuilding) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              embed: false,
              targetRoomCode: roomCode,
            ),
          ),
        );
      } else {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).courseBuildingNotFound(codePrefix),
          type: SnackBarType.warning,
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, AppLocalizations.of(context).courseLoadMapDataFailed(e.toString()), isError: true);
      }
    }
  }

  void _showRoomSelectionSheet(List<String> roomCodes) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  AppLocalizations.of(context).courseSelectRoomLocation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...roomCodes.map((room) {
                return ListTile(
                  leading: Icon(
                    Icons.map_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(AppLocalizations.of(context).courseGoToRoomLocation(room)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _handleNavigateToMap(room);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: AppLocalizations.of(context).courseOpenInBrowser,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppWebViewScreen(
                    url: 'https://webapp.yuntech.edu.tw/WebNewCAS/Course/Plan/Query.aspx?&${widget.year}&${widget.semester}&${widget.courseNo}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchDetail();
              },
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (_courseDetail == null) return const SizedBox.shrink();

    final detail = _courseDetail!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(detail),
        const SizedBox(height: 24),
        _buildSectionTitle(AppLocalizations.of(context).courseGoal),
        _buildContentCard(_formatContent(detail.goal)),
        const SizedBox(height: 24),
        _buildSectionTitle(AppLocalizations.of(context).courseOutline),
        _buildContentCard(_formatContent(detail.outline)),
        const SizedBox(height: 24),
        _buildSectionTitle(AppLocalizations.of(context).courseGrading),
        _buildContentCard(_formatContent(detail.grade)),
        const SizedBox(height: 24),
        _buildSyllabusPanel(detail.syllabus),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSyllabusPanel(List<CourseSyllabus> syllabus) {
    if (syllabus.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          AppLocalizations.of(context).courseSyllabus,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        collapsedBackgroundColor: colorScheme.surfaceContainerHighest,
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border.all(color: colorScheme.surfaceContainerHighest),
            ),
            child: Column(
              children: syllabus.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          item.week,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.content
                                  .split('\n')
                                  .map((line) => line.trimLeft())
                                  .join('\n')
                                  .trim(),
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                            if (item.method.isNotEmpty ||
                                item.remark.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item.method.isNotEmpty)
                                    Text(
                                      '📝 ${item.method}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  if (item.remark.isNotEmpty)
                                    Text(
                                      '📌 ${item.remark}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(CourseDetail detail) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _buildInfoRow(AppLocalizations.of(context).courseInstructor, detail.teacher),
            if (detail.teacherEmailAndTel != null &&
                detail.teacherEmailAndTel!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(AppLocalizations.of(context).courseContactInfo, detail.teacherEmailAndTel!),
            ],
            if (detail.deptCourseNo != null &&
                detail.deptCourseNo!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(AppLocalizations.of(context).courseCurriculumNo, detail.deptCourseNo!),
            ],
            const Divider(height: 8),
            _buildInfoRow(AppLocalizations.of(context).courseCredits, detail.credits),
            const Divider(height: 8),
            _buildInfoRow(
              AppLocalizations.of(context).courseScheduleClassroom,
              detail.timeRoom,
              crossAxisAlignment: CrossAxisAlignment.center,
              trailing: () {
                final rooms = _extractRoomCodes(detail.timeRoom);
                if (rooms.isEmpty) return null;
                return IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: AppLocalizations.of(context).mapModeTooltip,
                  onPressed: () {
                    if (rooms.length == 1) {
                      _handleNavigateToMap(rooms.first);
                    } else {
                      _showRoomSelectionSheet(rooms);
                    }
                  },
                );
              }(),
            ),
            if (detail.courseClass != null &&
                detail.courseClass!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(AppLocalizations.of(context).courseClass, detail.courseClass!),
            ],
            const Divider(height: 8),
            _buildInfoRow(AppLocalizations.of(context).courseRequiredElective, _annotateRequiredType(detail.requiredType)),
            if (detail.courseType != null && detail.courseType!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(AppLocalizations.of(context).courseType, detail.courseType!),
            ],
            if (detail.courseRemark != null &&
                detail.courseRemark!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow(AppLocalizations.of(context).courseRemark, detail.courseRemark!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Widget? trailing,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? AppLocalizations.of(context).courseNone : value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildContentCard(String content) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(content, style: const TextStyle(height: 1.6)),
      ),
    );
  }
}
