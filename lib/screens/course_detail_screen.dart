import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_detail_model.dart';
import '../services/api_service.dart';
import '../services/course_detail_cache.dart';
import '../utils/top_snack_bar.dart';

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
      // 使用快取服務：先讀 SP 快取 → miss 才打 API → 成功寫入快取
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
          _errorMessage = response?['message'] ?? '載入失敗';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '發生錯誤: $e';
        _isLoading = false;
      });
    }
  }

  String _formatContent(String text) {
    if (text.isEmpty) return '無資料';
    return text.split('\n').map((line) => line.trimLeft()).join('\n').trim();
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
            tooltip: '在瀏覽器開啟',
            onPressed: () async {
              final url = Uri.parse(
                'https://webapp.yuntech.edu.tw/WebNewCAS/Course/Plan/Query.aspx?&${widget.year}&${widget.semester}&${widget.courseNo}',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  showTopSnackBar(context, '無法開啟網頁', isError: true);
                }
              }
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
              child: const Text('重試'),
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
        _buildSectionTitle('教學目標'),
        _buildContentCard(_formatContent(detail.goal)),
        const SizedBox(height: 24),
        _buildSectionTitle('課程大綱'),
        _buildContentCard(_formatContent(detail.outline)),
        const SizedBox(height: 24),
        _buildSectionTitle('成績評量方式'),
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
          '教學計畫與進度',
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
            _buildInfoRow('授課教師', detail.teacher),
            if (detail.teacherEmailAndTel != null &&
                detail.teacherEmailAndTel!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow('聯絡資訊', detail.teacherEmailAndTel!),
            ],
            if (detail.deptCourseNo != null &&
                detail.deptCourseNo!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow('系所課號', detail.deptCourseNo!),
            ],
            const Divider(height: 8),
            _buildInfoRow('學分數', detail.credits),
            const Divider(height: 8),
            _buildInfoRow('上課時間教室', detail.timeRoom),
            if (detail.courseClass != null &&
                detail.courseClass!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow('開課班級', detail.courseClass!),
            ],
            const Divider(height: 8),
            _buildInfoRow('修別', detail.requiredType),
            if (detail.courseType != null && detail.courseType!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow('授課方式', detail.courseType!),
            ],
            if (detail.courseRemark != null &&
                detail.courseRemark!.isNotEmpty) ...[
              const Divider(height: 8),
              _buildInfoRow('備註', detail.courseRemark!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              value.isEmpty ? '無' : value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
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
