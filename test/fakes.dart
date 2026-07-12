import 'package:practice_tracker/data/practice_repository.dart';
import 'package:practice_tracker/models/practice_session.dart';

/// In-memory fake so widget/unit tests don't touch SQLite.
class FakePracticeRepository implements PracticeRepository {
  final List<PracticeSession> _sessions = [];
  int _nextId = 1;

  @override
  Future<PracticeSession> addSession(PracticeSession session) async {
    final saved = session.copyWith(id: _nextId++);
    _sessions.insert(0, saved);
    return saved;
  }

  @override
  Future<void> deleteAll() async => _sessions.clear();

  @override
  Future<List<PracticeSession>> getSessions() async => List.of(_sessions);

  @override
  Future<List<PracticeSession>> getSessionsSince(DateTime since) async =>
      _sessions.where((s) => !s.startedAt.isBefore(since)).toList();

  @override
  Future<int> getTotalSeconds() async =>
      _sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
}

/// A repository whose writes always fail — for exercising error paths.
class ThrowingPracticeRepository extends FakePracticeRepository {
  @override
  Future<PracticeSession> addSession(PracticeSession session) async {
    throw StateError('write failed');
  }
}
