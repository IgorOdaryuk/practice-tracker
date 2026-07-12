import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:practice_tracker/data/database_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late String path;

  setUp(() async {
    path = join(await sqflite.getDatabasesPath(), 'practice_tracker.db');
    await sqflite.deleteDatabase(path);
  });

  test('upgrading a v2 database to v3 preserves existing rows', () async {
    // Stand up the historical v2 schema (no CHECK constraints) and seed a row.
    final legacy = await sqflite.openDatabase(
      path,
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_id TEXT NOT NULL,
          duration_seconds INTEGER NOT NULL,
          started_at INTEGER NOT NULL,
          note TEXT NOT NULL DEFAULT ''
        )
      '''),
    );
    await legacy.insert('sessions', {
      'exercise_id': 'bass_groove',
      'duration_seconds': 420,
      'started_at': DateTime(2026, 7, 10).millisecondsSinceEpoch,
      'note': 'kept across migration',
    });
    await legacy.close();

    // Open through the service → triggers the v2→v3 upgrade.
    final service = DatabaseService();
    addTearDown(service.close);
    final db = await service.database;

    expect(await db.getVersion(), 3);
    final rows = await db.query('sessions');
    expect(rows, hasLength(1));
    expect(rows.single['duration_seconds'], 420);
    expect(rows.single['note'], 'kept across migration');
  });

  test('the v3 schema rejects invalid rows via CHECK constraints', () async {
    final service = DatabaseService();
    addTearDown(service.close);
    final db = await service.database; // fresh install → v3 with constraints

    // Negative duration violates CHECK(duration_seconds >= 0).
    await expectLater(
      db.insert('sessions', {
        'exercise_id': 'bass_groove',
        'duration_seconds': -5,
        'started_at': 0,
        'note': '',
      }),
      throwsA(isA<sqflite.DatabaseException>()),
    );

    // Empty exercise_id violates CHECK(length(exercise_id) > 0).
    await expectLater(
      db.insert('sessions', {
        'exercise_id': '',
        'duration_seconds': 10,
        'started_at': 0,
        'note': '',
      }),
      throwsA(isA<sqflite.DatabaseException>()),
    );
  });
}
