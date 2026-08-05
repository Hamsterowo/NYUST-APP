import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/utils/english_notice_policy.dart';

/// Locks the English-notice ticket: every decision the feature can get wrong
/// lives in this pure module, so it is exercised without building a widget and
/// without touching storage, the splash animation, or showDialog.
///
/// Only the three inputs go in and only `trigger` / `shouldPersist` come out —
/// how the dialog looks and how many times SharedPreferences is written are
/// implementation details that would break these tests without the feature
/// being broken.
void main() {
  ({EnglishNoticeTrigger trigger, bool shouldPersist}) decide({
    String? previous,
    required String current,
    required bool alreadyShown,
  }) => EnglishNoticePolicy.decide(
    previousLocale: previous,
    currentLocale: current,
    alreadyShown: alreadyShown,
  );

  group('decision table', () {
    test('any -> non-English never fires', () {
      for (final previous in <String?>[null, 'en', 'zh_TW']) {
        for (final alreadyShown in [false, true]) {
          final result = decide(
            previous: previous,
            current: 'zh_TW',
            alreadyShown: alreadyShown,
          );
          expect(
            result.trigger,
            EnglishNoticeTrigger.none,
            reason: 'previous=$previous alreadyShown=$alreadyShown',
          );
          expect(result.shouldPersist, isFalse);
        }
      }
    });

    test(
      'cold start already in English, not yet seen -> shows and persists',
      () {
        final result = decide(
          previous: null,
          current: 'en',
          alreadyShown: false,
        );
        expect(result.trigger, EnglishNoticeTrigger.coldStart);
        expect(result.shouldPersist, isTrue);
      },
    );

    test('cold start already in English, already seen -> stays quiet', () {
      final result = decide(previous: null, current: 'en', alreadyShown: true);
      expect(result.trigger, EnglishNoticeTrigger.none);
      expect(result.shouldPersist, isFalse);
    });

    test('Chinese -> English, not yet seen -> shows and persists', () {
      final result = decide(
        previous: 'zh_TW',
        current: 'en',
        alreadyShown: false,
      );
      expect(result.trigger, EnglishNoticeTrigger.switched);
      expect(result.shouldPersist, isTrue);
    });

    test(
      'Chinese -> English, already seen -> still shows, does not rewrite',
      () {
        final result = decide(
          previous: 'zh_TW',
          current: 'en',
          alreadyShown: true,
        );
        expect(result.trigger, EnglishNoticeTrigger.switched);
        expect(result.shouldPersist, isFalse);
      },
    );

    test('English -> English never fires', () {
      for (final alreadyShown in [false, true]) {
        final result = decide(
          previous: 'en',
          current: 'en',
          alreadyShown: alreadyShown,
        );
        expect(result.trigger, EnglishNoticeTrigger.none);
        expect(result.shouldPersist, isFalse);
      }
    });
  });

  group('locale normalization', () {
    test('regional English variants count as English', () {
      for (final current in ['en', 'en_US', 'en-GB', 'EN', 'en_Latn_US']) {
        expect(
          decide(
            previous: 'zh_TW',
            current: current,
            alreadyShown: false,
          ).trigger,
          EnglishNoticeTrigger.switched,
          reason: current,
        );
      }
    });

    test('Chinese variants are not English, in either position', () {
      for (final locale in ['zh', 'zh_TW', 'zh-Hant', 'zh_Hant_TW']) {
        expect(
          decide(previous: 'en', current: locale, alreadyShown: false).trigger,
          EnglishNoticeTrigger.none,
          reason: 'current=$locale',
        );
        expect(
          decide(
            previous: locale,
            current: 'en_US',
            alreadyShown: false,
          ).trigger,
          EnglishNoticeTrigger.switched,
          reason: 'previous=$locale',
        );
      }
    });

    test('a language that merely starts with "en" is not English', () {
      expect(
        decide(previous: 'zh_TW', current: 'eng', alreadyShown: false).trigger,
        EnglishNoticeTrigger.none,
      );
    });
  });

  group('long paths', () {
    test('switching back and forth shows each time, persisting only once', () {
      // Chinese -> English: first time ever, so the flag gets written.
      final first = decide(
        previous: 'zh_TW',
        current: 'en',
        alreadyShown: false,
      );
      expect(first.trigger, EnglishNoticeTrigger.switched);
      expect(first.shouldPersist, isTrue);

      // English -> Chinese: nothing.
      expect(
        decide(previous: 'en', current: 'zh_TW', alreadyShown: true).trigger,
        EnglishNoticeTrigger.none,
      );

      // Chinese -> English again: still shows, flag already written.
      final again = decide(
        previous: 'zh_TW',
        current: 'en',
        alreadyShown: true,
      );
      expect(again.trigger, EnglishNoticeTrigger.switched);
      expect(again.shouldPersist, isFalse);
    });

    test('a cold start after a switch-triggered notice stays quiet', () {
      expect(
        decide(previous: null, current: 'en_US', alreadyShown: true).trigger,
        EnglishNoticeTrigger.none,
      );
    });
  });
}
