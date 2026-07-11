import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/practice_repository.dart';

/// Aggregates the last 7 days of practice into per-exercise totals — the data
/// behind the weekly report graph. Presentation (which exercises count as gaps)
/// is left to the UI, which knows the chosen instrument's catalogue.
class ReportViewModel extends ChangeNotifier {
  ReportViewModel(this._repository) {
    unawaited(load());
  }

  final PracticeRepository _repository;

  bool _loading = false;
  Object? _error;
  Map<String, int> _secondsByExercise = const {};
  int _sessionCount = 0;

  bool get loading => _loading;
  Object? get error => _error;
  int get sessionCount => _sessionCount;

  int secondsFor(String exerciseId) => _secondsByExercise[exerciseId] ?? 0;

  Duration get total => Duration(
        seconds: _secondsByExercise.values.fold(0, (sum, s) => sum + s),
      );

  /// Highest single-exercise total this week (for scaling bars); 0 if empty.
  int get maxSeconds => _secondsByExercise.values.fold(
        0,
        (best, s) => s > best ? s : best,
      );

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final since = DateTime.now().subtract(const Duration(days: 7));
      final sessions = await _repository.getSessionsSince(since);
      final totals = <String, int>{};
      for (final session in sessions) {
        totals[session.exerciseId] =
            (totals[session.exerciseId] ?? 0) + session.durationSeconds;
      }
      _secondsByExercise = totals;
      _sessionCount = sessions.length;
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
