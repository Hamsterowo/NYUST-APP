import 'package:flutter/material.dart';
import 'grades_screen.dart';
import 'schedule_screen.dart';
import 'calendar_screen.dart';
import 'map_screen.dart';
import '../widgets/custom_app_bar.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  int _personalSelectedIndex = 0;
  int _campusSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: '資訊',
          bottom: TabBar(
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
                    children: const [
                      CalendarScreen(embed: true),
                      MapScreen(embed: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
