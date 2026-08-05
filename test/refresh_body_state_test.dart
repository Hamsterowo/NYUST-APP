import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/utils/refresh_body_state.dart';

/// 四個資料畫面共用的狀態解析：釘住 spec 議定的那張真值表。
void main() {
  group('resolveRefreshBody', () {
    test('主動更新中一律是骨架，不論資料狀態', () {
      for (final isEmpty in <bool?>[null, true, false]) {
        for (final failed in [true, false]) {
          expect(
            resolveRefreshBody(
              isEmpty: isEmpty,
              failed: failed,
              manualRefreshing: true,
            ),
            RefreshBodyState.skeleton,
            reason: 'isEmpty=$isEmpty failed=$failed',
          );
        }
      }
    });

    test('從未載入且尚未失敗是骨架', () {
      expect(
        resolveRefreshBody(
          isEmpty: null,
          failed: false,
          manualRefreshing: false,
        ),
        RefreshBodyState.skeleton,
      );
    });

    test('從未載入且已失敗是錯誤頁', () {
      expect(
        resolveRefreshBody(
          isEmpty: null,
          failed: true,
          manualRefreshing: false,
        ),
        RefreshBodyState.error,
      );
    });

    test('有資料且失敗時是列表，失敗不吃掉資料', () {
      expect(
        resolveRefreshBody(
          isEmpty: false,
          failed: true,
          manualRefreshing: false,
        ),
        RefreshBodyState.list,
      );
    });

    test('零筆是空狀態而不是骨架', () {
      expect(
        resolveRefreshBody(
          isEmpty: true,
          failed: false,
          manualRefreshing: false,
        ),
        RefreshBodyState.empty,
      );
    });

    test('零筆且失敗時回到空狀態，不退化成錯誤頁', () {
      expect(
        resolveRefreshBody(
          isEmpty: true,
          failed: true,
          manualRefreshing: false,
        ),
        RefreshBodyState.empty,
      );
    });

    test('有資料且未失敗是列表', () {
      expect(
        resolveRefreshBody(
          isEmpty: false,
          failed: false,
          manualRefreshing: false,
        ),
        RefreshBodyState.list,
      );
    });

    test('主動更新結束後回到原先的形態（骨架只是覆蓋）', () {
      // 同一份輸入，只切換 manualRefreshing：更新前後必須落回同一格。
      for (final isEmpty in <bool?>[null, true, false]) {
        for (final failed in [true, false]) {
          final before = resolveRefreshBody(
            isEmpty: isEmpty,
            failed: false,
            manualRefreshing: false,
          );
          final during = resolveRefreshBody(
            isEmpty: isEmpty,
            failed: failed,
            manualRefreshing: true,
          );
          final after = resolveRefreshBody(
            isEmpty: isEmpty,
            failed: failed,
            manualRefreshing: false,
          );
          expect(during, RefreshBodyState.skeleton);
          // 有資料時（零筆或有內容），失敗與否都回得到更新前的形態。
          if (isEmpty != null) {
            expect(after, before, reason: 'isEmpty=$isEmpty failed=$failed');
          }
        }
      }
    });
  });
}
