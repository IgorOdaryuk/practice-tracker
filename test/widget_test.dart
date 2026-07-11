import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:practice_tracker/data/practice_repository.dart';
import 'package:practice_tracker/data/settings_service.dart';
import 'package:practice_tracker/main.dart';
import 'package:practice_tracker/models/practice_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory fake so widget tests don't touch SQLite.
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Don't hit the network for fonts during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('boots into the onboarding welcome screen', (tester) async {
    await tester.pumpWidget(
      PracticeTrackerApp(
        repository: FakePracticeRepository(),
        settings: SettingsService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRACTICE TRACKER'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
