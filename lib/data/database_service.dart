import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the raw SQLite connection and schema (official cookbook: sqflite + path).
class DatabaseService {
  static const String _fileName = 'practice_tracker.db';

  /// v2: sessions keyed by `exercise_id` (v1 used a free `type` column).
  static const int _version = 2;

  static const String sessionsTable = 'sessions';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        // The v1 schema is incompatible and carried no real user data, so we
        // rebuild rather than migrate rows.
        await db.execute('DROP TABLE IF EXISTS $sessionsTable');
        await _createSchema(db);
      },
    );
  }

  Future<void> _createSchema(Database db) {
    return db.execute('''
      CREATE TABLE $sessionsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        started_at INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
