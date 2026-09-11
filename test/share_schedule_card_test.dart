import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/l10n/app_localizations.dart';
import 'package:yun_tool/models/schedule_event.dart';
import 'package:yun_tool/screens/schedule_screen.dart';

/// 分享課表圖卡的內容層級測試。
///
/// 刻意**不比對像素**：會真正傷到使用者的迴歸是「某類課程從圖上消失了」或
/// 「節次只剩英文字母、外校的人看不懂」，而不是某個字級差了 0.5。golden
/// 比對會因為改一次配色或字級就整批失效，擋住的問題卻不是這兩個。
ScheduleEvent course({
  required String name,
  String? weekday,
  List<String> times = const [],
  String room = '',
  String requiredType = '',
  String credits = '',
}) {
  return ScheduleEvent(
    semesterCourseNo: name,
    deptCourseNo: 'TEST001',
    name: name,
    courseClass: '',
    classType: '',
    requiredType: requiredType,
    credits: credits,
    timeRoomStr: '',
    teacher: '某老師',
    remark: '',
    weekday: weekday,
    times: times,
    room: room,
    year: '113',
    semester: '1',
  );
}

Future<void> pumpCard(
  WidgetTester tester,
  List<ScheduleEvent> courses, {
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: ShareScheduleCard(courses: courses),
        ),
      ),
    ),
  );
}

void main() {
  group('節次時刻', () {
    testWidgets('節次欄同時印出代碼與起始時刻', (tester) async {
      await pumpCard(tester, [
        course(name: '計算機概論', weekday: '1', times: ['A'], room: 'EE101'),
      ]);

      // 代碼仍在（雲科自己人的座標系）……
      expect(find.text('A'), findsOneWidget);
      // ……時刻也在（外校的人才解得開 A 是幾點）。
      expect(find.text('08:10'), findsOneWidget);
      expect(find.text('09:10'), findsOneWidget); // B 節
    });

    testWidgets('最後一節的結束時刻印在格線底部', (tester) async {
      await pumpCard(tester, [
        course(name: '計算機概論', weekday: '1', times: ['A']),
      ]);

      // 預設節次範圍到 G（16:00 結束）。其他列的結束時刻可以從下一列的起始
      // 時刻讀出來，只有最後一列沒有下一列，所以必須另外印。
      expect(find.text('16:00'), findsOneWidget);
    });
  });

  group('無安排上課時間的課程', () {
    testWidgets('沒有時段的課仍會出現在圖上', (tester) async {
      await pumpCard(tester, [
        course(name: '計算機概論', weekday: '1', times: ['A']),
        course(name: '專題研究', requiredType: '必修', credits: '3'),
      ]);

      expect(find.text('計算機概論'), findsOneWidget);
      // 舊版分享圖會把這門課整個丟掉，而且沒有任何跡象。
      expect(find.text('專題研究'), findsOneWidget);
      expect(find.text('必修 · 3 學分'), findsOneWidget);
    });

    testWidgets('全部課程都沒有時段時不畫空格線', (tester) async {
      await pumpCard(tester, [
        course(name: '碩士論文', credits: '6'),
        course(name: '書報討論', credits: '1'),
      ]);

      expect(find.text('碩士論文'), findsOneWidget);
      expect(find.text('書報討論'), findsOneWidget);
      // 一張全空的格線看起來像載入失敗，而不是「我沒有固定上課時間」。
      expect(find.text('週一'), findsNothing);
      expect(find.text('08:10'), findsNothing);
    });
  });

  group('版面不爆', () {
    // 卡片高度是算出來的固定值，一旦公式與實際佈局對不上就是 RenderFlex
    // overflow——而分享圖是離屏產生的，畫面上看不到任何異狀，只會得到一張
    // 被裁掉一截的圖。這裡讓測試框架替我們抓。
    final dense = <ScheduleEvent>[
      for (var day = 1; day <= 7; day++)
        for (final period in const ['X', 'A', 'C', 'E', 'G', 'Z', 'J', 'L'])
          course(
            name: '課程$day$period',
            weekday: '$day',
            times: [period],
            room: 'EE$day$period',
          ),
      course(name: '專題研究', requiredType: '必修', credits: '3'),
      course(name: '書報討論', requiredType: '必修', credits: '1'),
      course(name: '碩士論文', requiredType: '必修', credits: '6'),
      course(name: '服務學習', requiredType: '選修', credits: '0'),
    ];

    testWidgets('7 天 × 15 節 + 4 門無時間課（中文）', (tester) async {
      await pumpCard(tester, dense);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7 天 × 15 節 + 4 門無時間課（英文）', (tester) async {
      await pumpCard(tester, dense, locale: const Locale('en'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('系統字級放大時仍不爆版', (tester) async {
      // 分享圖一律以標準字級繪製，否則使用者的字級設定會把固定尺寸推翻。
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpCard(tester, dense);
      expect(tester.takeException(), isNull);
    });
  });

  group('heightFor', () {
    test('高度隨無時間課程數量增加', () {
      final withoutExtras = [
        course(name: '計算機概論', weekday: '1', times: ['A']),
      ];
      final withExtras = [...withoutExtras, course(name: '專題研究')];

      expect(
        ShareScheduleCard.heightFor(withExtras),
        greaterThan(ShareScheduleCard.heightFor(withoutExtras)),
      );
    });

    test('高度隨節次列數增加（有夜間課時更高）', () {
      final dayOnly = [
        course(name: '計算機概論', weekday: '1', times: ['A']),
      ];
      final withNight = [
        ...dayOnly,
        course(name: '夜間選修', weekday: '3', times: ['L']),
      ];

      expect(
        ShareScheduleCard.heightFor(withNight),
        greaterThan(ShareScheduleCard.heightFor(dayOnly)),
      );
    });

    test('沒有任何課時不會算出負高度', () {
      expect(ShareScheduleCard.heightFor(const []), greaterThan(0));
    });
  });
}
