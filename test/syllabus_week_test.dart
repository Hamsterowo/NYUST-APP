import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/l10n/app_localizations.dart';
import 'package:yun_tool/utils/syllabus_week.dart';

void main() {
  group('parseSyllabusWeek', () {
    test('學校的固定格式 第N週 抽得到數字', () {
      expect(parseSyllabusWeek('第1週'), 1);
      expect(parseSyllabusWeek('第5週'), 5);
      expect(parseSyllabusWeek('第18週'), 18);
    });

    test('頭尾空白不影響', () {
      expect(parseSyllabusWeek('  第7週 '), 7);
    });

    test('沒有數字時回 null，呼叫端據此原樣顯示原字串', () {
      expect(parseSyllabusWeek(''), isNull);
      expect(parseSyllabusWeek('備註'), isNull);
      expect(parseSyllabusWeek('第Ｎ週'), isNull);
    });
  });

  group('courseSyllabusWeek', () {
    late AppLocalizations zh;
    late AppLocalizations en;

    setUpAll(() async {
      zh = await AppLocalizations.delegate.load(const Locale('zh'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('中文維持學校原本的寫法', () {
      expect(zh.courseSyllabusWeek(1), '第1週');
      expect(zh.courseSyllabusWeek(18), '第18週');
    });

    test('英文由 App 這側翻譯 —— 學校的課綱頁沒有英文版', () {
      expect(en.courseSyllabusWeek(1), 'Week 1');
      expect(en.courseSyllabusWeek(18), 'Week 18');
    });

    test('不加千分位分隔符（週次是序數不是數量）', () {
      expect(en.courseSyllabusWeek(1000), 'Week 1000');
    });
  });
}
