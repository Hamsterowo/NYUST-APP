import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_tool/database/database.dart';
import 'package:yun_tool/models/schedule_event.dart';
import 'package:yun_tool/repositories/schedule_repository.dart';
import 'package:yun_tool/services/api_service.dart';
import 'package:yun_tool/services/scrape_result.dart';

/// The semester switcher only renders when the app knows the semester list.
/// That list used to live in memory and be filled in only by a live fetch, so
/// an offline cold start hid the switcher and the other semesters became
/// unreachable even though their courses were cached. These tests pin the
/// persistence that fixes it — including that the reserved row it is stored
/// under never leaks into the per-semester course cache.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('yun_tool_course_repo');

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

  late ScheduleRepository repo;

  setUp(() async {
    final db = AppDatabase.instance;
    await db.delete(db.semesterScheduleCacheTable).go();
    await db.delete(db.cacheMeta).go();
    repo = ScheduleRepository(db, ApiService());
  });

  ScheduleEvent course(String name) => ScheduleEvent(
    semesterCourseNo: 'C-1',
    deptCourseNo: '',
    name: name,
    courseClass: '',
    classType: '',
    requiredType: '',
    credits: '3',
    timeRoomStr: '',
    teacher: '',
    remark: '',
    weekday: '1',
    times: const ['A'],
  );

  group('semester list persistence', () {
    test('round-trips the options and the current semester', () async {
      await repo.saveSemesterList(const [
        SemesterOption(value: '1142', label: '114學年第2學期'),
        SemesterOption(value: '1141', label: '114學年第1學期'),
      ], '1142');

      final loaded = await repo.loadSemesterList();

      expect(loaded, isNotNull);
      expect(loaded!.currentSemester, '1142');
      expect(loaded.semesters.map((s) => s.value), ['1142', '1141']);
      expect(loaded.semesters.first.label, '114學年第2學期');
    });

    test('returns null when nothing has been stored yet', () async {
      expect(await repo.loadSemesterList(), isNull);
    });

    test('an empty list is not stored', () async {
      await repo.saveSemesterList(const [], '1142');

      expect(await repo.loadSemesterList(), isNull);
    });

    test(
      're-saving replaces the previous list rather than adding a row',
      () async {
        await repo.saveSemesterList(const [
          SemesterOption(value: '1141', label: '舊'),
        ], '1141');
        await repo.saveSemesterList(const [
          SemesterOption(value: '1142', label: '新'),
        ], '1142');

        final loaded = await repo.loadSemesterList();

        expect(loaded!.semesters.map((s) => s.value), ['1142']);
        expect(loaded.currentSemester, '1142');
      },
    );
  });

  group('reserved row does not leak', () {
    test('the semester list is absent from the cached course map', () async {
      await repo.saveCachedSemester('1141', [course('作業系統')]);
      await repo.saveSemesterList(const [
        SemesterOption(value: '1142', label: '114學年第2學期'),
        SemesterOption(value: '1141', label: '114學年第1學期'),
      ], '1142');

      final cached = await repo.loadCachedSemesters();

      expect(
        cached.keys,
        ['1141'],
        reason: 'the reserved row must not be read back as a semester',
      );
      expect(cached['1141']!.single.name, '作業系統');
    });

    test(
      'cached courses survive alongside the list in either write order',
      () async {
        await repo.saveSemesterList(const [
          SemesterOption(value: '1142', label: '114學年第2學期'),
        ], '1142');
        await repo.saveCachedSemester('1132', [course('計算機概論')]);

        final cached = await repo.loadCachedSemesters();
        final loaded = await repo.loadSemesterList();

        expect(cached.keys, ['1132']);
        expect(loaded!.semesters.single.value, '1142');
      },
    );
  });

  // The class is named for the schedule, and so is everything inside it — but
  // the dataset key is written to CacheMeta on the user's device. Aligning it
  // with a sibling ('course', to match some future rename) would compile, pass
  // every other test, and silently orphan the TTL record of every existing
  // install, costing them one needless fetch. Hence a test rather than a
  // comment.
  group('cache key is a storage contract', () {
    test('refresh stamps CacheMeta under "schedule"', () async {
      final api = ApiService();
      final wasDemo = api.isDemoMode;
      api.isDemoMode = true;
      addTearDown(() => api.isDemoMode = wasDemo);

      final result = await repo.refresh(force: true);
      expect(result.outcome, RefreshOutcome.success);

      final db = AppDatabase.instance;
      final meta = await db.select(db.cacheMeta).get();

      expect(
        meta.map((m) => m.datasetKey),
        contains('schedule'),
        reason: 'existing installs look their schedule TTL up under this key',
      );
    });
  });
}
