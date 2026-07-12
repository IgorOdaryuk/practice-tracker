import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/practice_repository.dart';
import '../data/settings_service.dart';
import '../models/exercise.dart';
import '../models/practice_session.dart';

enum TimerStatus { idle, running, review }

/// UI logic for the practice timer (architecture guide: ViewModel).
///
/// Elapsed time is derived from a wall-clock start timestamp, not from counting
/// ticks: a `Timer.periodic` only *nudges the UI* once a second, so a dropped,
/// late, or backgrounded tick can never make the count drift. When the app is
/// paused (locked / backgrounded) the session keeps accruing real time, and on
/// resume the value is recomputed from the clock.
///
/// The active session is mirrored to [SettingsService] so a kill/crash before
/// Save leaves a recoverable draft instead of losing the practice.
class TimerViewModel extends ChangeNotifier {
  TimerViewModel(
    this._repository, {
    this._settings,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (_settings != null) unawaited(_restoreDraft());
  }

  final PracticeRepository _repository;
  final SettingsService? _settings;
  final DateTime Function() _now;

  Timer? _ticker;
  Exercise? _exercise;
  TimerStatus _status = TimerStatus.idle;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;
  bool _saving = false;
  Object? _error;

  /// A session recovered from a previous run is surfaced so the UI can tell the
  /// user "we picked up where you left off".
  bool _restoredFromDraft = false;

  Exercise? get exercise => _exercise;
  TimerStatus get status => _status;
  Duration get elapsed => _elapsed;
  bool get saving => _saving;
  Object? get error => _error;
  bool get isRunning => _status == TimerStatus.running;
  bool get restoredFromDraft => _restoredFromDraft;

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
    _startedAt ??= _now();
    _restoredFromDraft = false;
    _syncElapsed();
    _startTicker();
    unawaited(_persistDraft());
    notifyListeners();
  }

  void stop() {
    _stopTicker();
    _syncElapsed();
    if (_elapsed.inSeconds == 0) {
      _reset();
      return;
    }
    _status = TimerStatus.review;
    notifyListeners();
  }

  /// Recomputes elapsed from the wall clock. Call when the app resumes: the UI
  /// thread was frozen while backgrounded, so the ticker missed those seconds.
  void refreshFromClock() {
    if (_status != TimerStatus.running) return;
    _syncElapsed();
    notifyListeners();
  }

  /// Called when the app is backgrounded: freeze the ticker (the OS may suspend
  /// us) and flush the latest elapsed value to disk so a kill is recoverable.
  void handleAppPaused() {
    if (_status != TimerStatus.running) return;
    _syncElapsed();
    unawaited(_persistDraft());
    notifyListeners();
  }

  /// Persists the reviewed session and returns it (for the report screen).
  /// Returns `null` on nothing-to-save *or* on failure — check [error] to tell
  /// them apart; on failure the review state is kept so the user can retry.
  Future<PracticeSession?> save(String note) async {
    final exercise = _exercise;
    if (_status != TimerStatus.review || _saving || exercise == null) {
      return null;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _repository.addSession(
        PracticeSession(
          exerciseId: exercise.id,
          durationSeconds: _elapsed.inSeconds,
          startedAt: _startedAt ?? _now(),
          note: note.trim(),
        ),
      );
      await _clearDraft();
      // Intentionally NOT resetting here — the screen keeps the review state
      // until the post-session report is shown, then calls reset(). This avoids
      // the timer visibly snapping to 0:00 before the report appears.
      return saved;
    } catch (error) {
      _error = error;
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void discard() {
    unawaited(_clearDraft());
    _reset(keepExercise: true);
  }

  /// Clears the timer back to idle (keeps the chosen exercise). Called once the
  /// post-session report has been presented.
  void reset() {
    unawaited(_clearDraft());
    _reset(keepExercise: true);
  }

  // --- internals ---

  void _syncElapsed() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    final delta = _now().difference(startedAt);
    _elapsed = delta.isNegative ? Duration.zero : delta;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncElapsed();
      // Cheap throttled checkpoint so a kill loses at most a few seconds.
      if (_elapsed.inSeconds % 10 == 0) unawaited(_persistDraft());
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _reset({bool keepExercise = false}) {
    _stopTicker();
    _status = TimerStatus.idle;
    _elapsed = Duration.zero;
    _startedAt = null;
    _error = null;
    _restoredFromDraft = false;
    if (!keepExercise) _exercise = null;
    notifyListeners();
  }

  Future<void> _persistDraft() async {
    final settings = _settings;
    final startedAt = _startedAt;
    final exercise = _exercise;
    if (settings == null || startedAt == null || exercise == null) return;
    await settings.saveSessionDraft(
      SessionDraft(
        exerciseId: exercise.id,
        startedAt: startedAt,
        elapsedSeconds: _elapsed.inSeconds,
      ),
    );
  }

  Future<void> _clearDraft() async => _settings?.clearSessionDraft();

  /// On launch, recover a session interrupted by a kill/crash. We restore into
  /// the *review* state (not running): we know when it started and how far it
  /// had counted, but not whether the user is still playing — so we surface it
  /// for Save/Discard rather than silently resuming a possibly-stale count.
  Future<void> _restoreDraft() async {
    final settings = _settings;
    if (settings == null) return;
    final draft = await settings.readSessionDraft();
    if (draft == null) return;
    final exercise = exerciseById(draft.exerciseId);
    if (exercise == null || draft.elapsedSeconds <= 0) {
      await settings.clearSessionDraft();
      return;
    }
    _exercise = exercise;
    _startedAt = draft.startedAt;
    _elapsed = Duration(seconds: draft.elapsedSeconds);
    _status = TimerStatus.review;
    _restoredFromDraft = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
