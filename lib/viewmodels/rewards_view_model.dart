import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/practice_repository.dart';
import '../models/rewards.dart';

/// Turns lifetime practice time into Beats and reward-tier progress.
class RewardsViewModel extends ChangeNotifier {
  RewardsViewModel(this._repository) {
    unawaited(load());
  }

  final PracticeRepository _repository;

  bool _loading = false;
  Object? _error;
  int _totalSeconds = 0;

  bool get loading => _loading;
  Object? get error => _error;
  int get beats => beatsFromSeconds(_totalSeconds);
  Duration get totalTime => Duration(seconds: _totalSeconds);

  RewardTier? get nextTier => nextTierAfter(beats);

  /// 0..1 progress toward [nextTier] (1 when everything is unlocked).
  double get progressToNext {
    final tier = nextTier;
    if (tier == null) return 1;
    final previous = kRewardTiers
        .where((t) => t.beats <= beats)
        .fold<int>(0, (max, t) => t.beats > max ? t.beats : max);
    final span = tier.beats - previous;
    if (span <= 0) return 1;
    return ((beats - previous) / span).clamp(0.0, 1.0);
  }

  bool isUnlocked(RewardTier tier) => beats >= tier.beats;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _totalSeconds = await _repository.getTotalSeconds();
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
