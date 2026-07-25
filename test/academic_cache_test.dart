import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/database/database.dart';
import 'package:yun_tool/services/academic_cache.dart';

/// Locks the account-isolation guarantee: cached academic data belongs to
/// exactly one account, and a different account signing in never inherits it.
///
/// The point of [AcademicCache] is that this works **without** the data layer
/// being alive — the old behaviour routed clearing through a lazily-created
/// provider, so a sign-out at startup left the previous account's rows behind.
/// These tests therefore call it directly, with nothing else constructed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In-memory stand-in for the platform secure storage channel.
  late Map<String, String> storage;

  // Drift needs a real directory; without it the lazy open fails as an
  // unhandled async error. Pointing it at a temp dir lets the database
  // actually open, so the table wipe is exercised rather than skipped.
  final tempDir = Directory.systemTemp.createTempSync('yun_tool_cache_test');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    storage = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = (call.arguments as Map?) ?? const {};
            final key = args['key']?.toString();
            switch (call.method) {
              case 'write':
                storage[key!] = args['value']?.toString() ?? '';
                return null;
              case 'read':
                return storage[key];
              case 'delete':
                storage.remove(key);
                return null;
              case 'deleteAll':
                storage.clear();
                return null;
              case 'readAll':
                return storage;
              case 'containsKey':
                return storage.containsKey(key);
            }
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  group('cache ownership', () {
    test(
      'the first account to claim an empty cache becomes its owner',
      () async {
        await AcademicCache.claimFor('B11217990');

        expect(storage['cache_owner_id'], 'B11217990');
      },
    );

    test('re-claiming by the same account leaves the cache in place', () async {
      await AcademicCache.claimFor('B11217990');
      storage['cache_grades'] = '{"success":true}';

      await AcademicCache.claimFor('B11217990');

      expect(
        storage['cache_grades'],
        isNotNull,
        reason: 'the same account must not have its own cache wiped',
      );
      expect(storage['cache_owner_id'], 'B11217990');
    });

    test('a different account wipes the previous account\'s cache', () async {
      await AcademicCache.claimFor('B11111111');
      storage['cache_grades'] = '{"success":true,"grades":["previous"]}';

      await AcademicCache.claimFor('B12222222');

      expect(
        storage['cache_grades'],
        isNull,
        reason: "the next account must not inherit the previous one's data",
      );
      expect(storage['cache_owner_id'], 'B12222222');
    });

    test(
      'a cache with no recorded owner is treated as foreign and wiped',
      () async {
        // Simulates an install upgraded from a build that never recorded one.
        storage['cache_grades'] = '{"success":true,"grades":["legacy"]}';

        await AcademicCache.claimFor('B11217990');

        expect(storage['cache_grades'], isNull);
        expect(storage['cache_owner_id'], 'B11217990');
      },
    );

    test('an unknown account id is a no-op, not a wipe', () async {
      await AcademicCache.claimFor('B11217990');
      storage['cache_grades'] = '{"success":true}';

      await AcademicCache.claimFor('');

      expect(storage['cache_grades'], isNotNull);
      expect(storage['cache_owner_id'], 'B11217990');
    });
  });

  group('clearing', () {
    test(
      'clearAll drops the cached grades copy and the owner record',
      () async {
        await AcademicCache.claimFor('B11217990');
        storage['cache_grades'] = '{"success":true}';

        await AcademicCache.clearAll();

        expect(storage['cache_grades'], isNull);
        expect(storage['cache_owner_id'], isNull);
      },
    );

    test('clearAll wipes the cached rows in the database too', () async {
      final db = AppDatabase.instance;
      await db
          .into(db.cacheMeta)
          .insert(
            CacheMetaCompanion.insert(
              datasetKey: 'grades',
              updatedAt: DateTime.now(),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
      expect(await db.select(db.cacheMeta).get(), isNotEmpty);

      await AcademicCache.clearAll();

      expect(
        await db.select(db.cacheMeta).get(),
        isEmpty,
        reason: 'the freshness markers must go, or refresh would skip fetching',
      );
    });

    test('after clearing, the next account claims a clean cache', () async {
      await AcademicCache.claimFor('B11111111');
      storage['cache_grades'] = '{"success":true}';
      await AcademicCache.clearAll();

      await AcademicCache.claimFor('B12222222');

      expect(storage['cache_grades'], isNull);
      expect(storage['cache_owner_id'], 'B12222222');
    });
  });
}
