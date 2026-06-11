import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'grades_screen.dart';
import 'schedule_screen.dart';
import 'calendar_screen.dart';
import 'map_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/data_provider.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _personalSelectedIndex = 0;
  int _campusSelectedIndex = 0;
  bool _isCalendarLoading = false;
  final GlobalKey<CalendarScreenState> _calendarKey = GlobalKey<CalendarScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // Rebuild InfoScreen when tab switches to update app bar actions
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    final data = context.watch<DataProvider>();

    // Check if personal tab is selected
    if (_tabController.index == 0) {
      if (_personalSelectedIndex == 0) {
        // 個人課表
        if (data.isLoadingSchedule) {
          return const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
            ),
          ];
        }
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理課表',
            onPressed: () => data.fetchSchedule(),
          ),
        ];
      } else {
        // 學期成績
        final isLoadingGrades = data.isLoadingGrades || data.isLoadingGraduation;
        if (isLoadingGrades) {
          return const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
            ),
          ];
        }
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理成績',
            onPressed: () async {
              await Future.wait([
                data.fetchGrades(),
                data.fetchGraduation(),
              ]);
            },
          ),
        ];
      }
    } else {
      // 校園資訊
      if (_campusSelectedIndex == 0) {
        // 校園行事曆
        if (_isCalendarLoading) {
          return const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
            ),
          ];
        }
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理行事曆',
            onPressed: () async {
              await _calendarKey.currentState?.refreshData();
            },
          ),
        ];
      } else {
        // 校園地圖
        return const [];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '資訊',
        actions: _buildAppBarActions(context),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: '個人資訊',
            ),
            Tab(
              text: '校園資訊',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('個人課表'),
                        icon: Icon(Icons.table_chart_outlined),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('學期成績'),
                        icon: Icon(Icons.school_outlined),
                      ),
                    ],
                    selected: { _personalSelectedIndex },
                    onSelectionChanged: (set) {
                      setState(() {
                        _personalSelectedIndex = set.first;
                      });
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _personalSelectedIndex,
                  children: const [
                    ScheduleScreen(embed: true),
                    GradesScreen(embed: true),
                  ],
                ),
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('校園行事曆'),
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('校園地圖'),
                        icon: Icon(Icons.map_outlined),
                      ),
                    ],
                    selected: { _campusSelectedIndex },
                    onSelectionChanged: (set) {
                      setState(() {
                        _campusSelectedIndex = set.first;
                      });
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _campusSelectedIndex,
                  children: [
                    CalendarScreen(
                      key: _calendarKey,
                      embed: true,
                      onLoadingChanged: (loading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isCalendarLoading = loading;
                            });
                          }
                        });
                      },
                    ),
                    const MapScreen(embed: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
