import '../models/practice_session.dart';
import 'database_service.dart';

/// Data-layer contract for practice sessions. ViewModels depend on this, not on
/// sqflite, so a fake can be swapped in for tests.
abstract interface class PracticeRepository {
  Future<List<PracticeSession>> getSessions();
  Future<List<PracticeSession>> getSessionsSince(DateTime since);
  Future<PracticeSession> addSession(PracticeSession session);

  /// Sum of all recorded practice time, in seconds (drives Beats).
  Future<int> getTotalSeconds();
  Future<void> deleteAll();
}

class SqflitePracticeRepository implements PracticeRepository {
  SqflitePracticeRepository(this._db);

  final DatabaseService _db;

  @override
  Future<List<PracticeSession>> getSessions() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseService.sessionsTable,
      orderBy: 'started_at DESC',
    );
    return rows.map(PracticeSession.fromMap).toList();
  }

  @override
  Future<List<PracticeSession>> getSessionsSince(DateTime since) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseService.sessionsTable,
      where: 'started_at >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
      orderBy: 'started_at DESC',
    );
    return rows.map(PracticeSession.fromMap).toList();
  }

  @override
  Future<PracticeSession> addSession(PracticeSession session) async {
    final db = await _db.database;
    final id = await db.insert(DatabaseService.sessionsTable, session.toMap());
    return session.copyWith(id: id);
  }

  @override
  Future<int> getTotalSeconds() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_seconds), 0) AS total '
      'FROM ${DatabaseService.sessionsTable}',
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete(DatabaseService.sessionsTable);
  }
}
