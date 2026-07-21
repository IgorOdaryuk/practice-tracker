import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the raw SQLite connection and schema (official cookbook: sqflite + path).
class DatabaseService {
  static const String _fileName = 'practice_tracker.db';

  /// Schema history:
  ///  v1 — free `type` column (pre-release, no real user data).
  ///  v2 — sessions keyed by `exercise_id`.
  ///  v3 — added CHECK constraints for row integrity.
  static const int _version = 3;

  static const String sessionsTable = 'sessions';

  /// Optional path override. Production leaves this null → the app's real file
  /// under `getDatabasesPath()`. Tests pass their own path (a unique file or
  /// `inMemoryDatabasePath`) so suites never contend on one shared on-disk DB.
  final String? _pathOverride;

  DatabaseService({String? path}) : _pathOverride = path;

  // Cache the *future*, not the resolved Database: two concurrent first calls
  // must share one `_open()`, otherwise each opens its own connection.
  Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _open();

  Future<Database> _open() async {
    final path = _pathOverride ?? join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) => _createSchema(db),
      onUpgrade: _onUpgrade,
      // App keeps sqflite's shared handle; an overridden path (tests) opens a
      // private connection so parallel suites can't lock each other out.
      singleInstance: _pathOverride == null,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrations run in order; each guarded by the version it introduces, so a
    // future bump never re-runs (or worse, re-drops) an earlier step.
    if (oldVersion < 2) {
      // v1's schema is incompatible and carried no real user data, so we drop
      // and recreate rather than migrate rows. Scoped to the v1→v2 hop only.
      await db.execute('DROP TABLE IF EXISTS $sessionsTable');
      await _createSchemaV2(db);
    }
    if (oldVersion < 3) {
      await _migrateV2toV3(db);
    }
  }

  /// Final (v3) schema, used for fresh installs.
  Future<void> _createSchema(Database db) {
    return db.execute('''
      CREATE TABLE $sessionsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id TEXT NOT NULL CHECK(length(exercise_id) > 0),
        duration_seconds INTEGER NOT NULL CHECK(duration_seconds >= 0),
        started_at INTEGER NOT NULL CHECK(started_at >= 0),
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// Historical v2 schema (no CHECK constraints) — kept so the v1→v2 migration
  /// step reproduces exactly what shipped, before v3 layers constraints on top.
  Future<void> _createSchemaV2(Database db) {
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

  /// Adds CHECK constraints without losing data: SQLite can't ALTER them in, so
  /// rebuild via a constrained table and copy the (valid) existing rows over.
  Future<void> _migrateV2toV3(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE ${sessionsTable}_v3(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_id TEXT NOT NULL CHECK(length(exercise_id) > 0),
          duration_seconds INTEGER NOT NULL CHECK(duration_seconds >= 0),
          started_at INTEGER NOT NULL CHECK(started_at >= 0),
          note TEXT NOT NULL DEFAULT ''
        )
      ''');
      await txn.execute('''
        INSERT INTO ${sessionsTable}_v3 (id, exercise_id, duration_seconds, started_at, note)
        SELECT id, exercise_id, duration_seconds, started_at, note
        FROM $sessionsTable
        WHERE length(exercise_id) > 0 AND duration_seconds >= 0 AND started_at >= 0
      ''');
      await txn.execute('DROP TABLE $sessionsTable');
      await txn.execute('ALTER TABLE ${sessionsTable}_v3 RENAME TO $sessionsTable');
    });
  }

  Future<void> close() async {
    final future = _dbFuture;
    _dbFuture = null;
    if (future != null) {
      final db = await future;
      await db.close();
    }
  }
}
