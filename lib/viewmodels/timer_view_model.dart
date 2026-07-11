import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/practice_repository.dart';
import '../models/exercise.dart';
import '../models/practice_session.dart';

enum TimerStatus { idle, running, review }

/// UI logic for the practice timer (architecture guide: ViewModel).
class TimerViewModel extends ChangeNotifier {
  TimerViewModel(this._repository);

  final PracticeRepository _repository;

  Timer? _ticker;
  Exercise? _exercise;
  TimerStatus _status = TimerStatus.idle;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;
  bool _saving = false;

  Exercise? get exercise => _exercise;
  TimerStatus get status => _status;
  Duration get elapsed => _elapsed;
  bool get saving => _saving;
  bool get isRunning => _status == TimerStatus.running;

  /// Picking an exercise is only allowed before the timer starts.
  void selectExercise(Exercise exercise) {
    if (_status != TimerStatus.idle) return;
    if (_exercise?.id == exercise.id) return;
    _exercise = exercise;
    notifyListeners();
  }

  void start() {
    if (_exercise == null || _status == TimerStatus.running) return;
    _status = TimerStatus.running;
    _startedAt ??= DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
  }

  void stop() {
    _stopTicker();
    if (_elapsed == Duration.zero) {
      _reset();
      return;
    }
    _status = TimerStatus.review;
    notifyListeners();
  }

  /// Persists the reviewed session and returns it (for the report screen).
  /// Returns `null` if there's nothing to save.
  Future<PracticeSession?> save(String note) async {
    final exercise = _exercise;
    if (_status != TimerStatus.review || _saving || exercise == null) {
      return null;
    }
    _saving = true;
    notifyListeners();
    final saved = await _repository.addSession(
      PracticeSession(
        exerciseId: exercise.id,
        durationSeconds: _elapsed.inSeconds,
        startedAt: _startedAt ?? DateTime.now(),
        note: note.trim(),
      ),
    );
    _saving = false;
    // Intentionally NOT resetting here — the screen keeps the review state
    // until the post-session report is shown, then calls reset(). This avoids
    // the timer visibly snapping to 0:00 before the report appears.
    notifyListeners();
    return saved;
  }

  void discard() => _reset(keepExercise: true);

  /// Clears the timer back to idle (keeps the chosen exercise). Called once the
  /// post-session report has been presented.
  void reset() => _reset(keepExercise: true);

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _reset({bool keepExercise = false}) {
    _stopTicker();
    _status = TimerStatus.idle;
    _elapsed = Duration.zero;
    _startedAt = null;
    if (!keepExercise) _exercise = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
