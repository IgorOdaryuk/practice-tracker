import 'package:flutter_test/flutter_test.dart';
import 'package:practice_tracker/data/database_service.dart';
import 'package:practice_tracker/data/practice_repository.dart';
import 'package:practice_tracker/models/practice_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Run the real SQLite engine on the host (not a mock) via the FFI factory.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;
  late PracticeRepository repo;

  setUp(() async {
    // Private in-memory DB per test: this suite exercises CRUD, not migrations,
    // so it needs no on-disk file — and staying off the shared file removes the
    // cross-suite lock contention that made this suite flaky.
    db = DatabaseService(path: inMemoryDatabasePath);
    repo = SqflitePracticeRepository(db);
  });

  tearDown(() async {
    await repo.deleteAll();
    await db.close();
  });

  test('inserts a session and reads it back with an assigned id', () async {
    final saved = await repo.addSession(
      PracticeSession(
        exerciseId: 'bass_groove',
        durationSeconds: 300,
        startedAt: DateTime(2026, 7, 11, 9),
        note: 'metronome at 80bpm',
      ),
    );

    expect(saved.id, isNotNull);

    final all = await repo.getSessions();
    expect(all, hasLength(1));
    expect(all.single.exerciseId, 'bass_groove');
    expect(all.single.durationSeconds, 300);
    expect(all.single.note, 'metronome at 80bpm');
    expect(all.single.startedAt, DateTime(2026, 7, 11, 9));
  });

  test('getSessionsSince filters by start time', () async {
    final now = DateTime(2026, 7, 11, 12);
    await repo.addSession(PracticeSession(
      exerciseId: 'guitar_scales',
      durationSeconds: 120,
      startedAt: now.subtract(const Duration(days: 10)), // old
    ));
    await repo.addSession(PracticeSession(
      exerciseId: 'guitar_picking',
      durationSeconds: 240,
      startedAt: now.subtract(const Duration(days: 2)), // within a week
    ));

    final recent =
        await repo.getSessionsSince(now.subtract(const Duration(days: 7)));
    expect(recent, hasLength(1));
    expect(recent.single.exerciseId, 'guitar_picking');
  });

  test('getTotalSeconds sums every session', () async {
    await repo.addSession(PracticeSession(
      exerciseId: 'bass_scales',
      durationSeconds: 60,
      startedAt: DateTime(2026, 7, 10),
    ));
    await repo.addSession(PracticeSession(
      exerciseId: 'bass_arps',
      durationSeconds: 90,
      startedAt: DateTime(2026, 7, 11),
    ));

    expect(await repo.getTotalSeconds(), 150);
  });

  test('getTotalSeconds is zero on an empty table', () async {
    expect(await repo.getTotalSeconds(), 0);
  });
}
