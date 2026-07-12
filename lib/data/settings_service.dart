import 'package:shared_preferences/shared_preferences.dart';

import '../models/instrument.dart';

/// A practice session that was in progress when the app was last closed, so it
/// can be recovered instead of silently lost.
class SessionDraft {
  const SessionDraft({
    required this.exerciseId,
    required this.startedAt,
    required this.elapsedSeconds,
  });

  final String exerciseId;
  final DateTime startedAt;
  final int elapsedSeconds;
}

/// Small persisted-preferences wrapper (onboarding flag, chosen instrument, and
/// the in-progress session draft used for crash/kill recovery).
class SettingsService {
  static const String _kOnboarded = 'onboarding_complete';
  static const String _kFilter = 'instrument_filter';
  static const String _kDraftExercise = 'draft_exercise_id';
  static const String _kDraftStartedAt = 'draft_started_at';
  static const String _kDraftElapsed = 'draft_elapsed_seconds';

  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarded) ?? false;
  }

  Future<InstrumentFilter> instrumentFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kFilter);
    return name == null
        ? InstrumentFilter.all
        : InstrumentFilter.fromName(name);
  }

  Future<void> completeOnboarding(InstrumentFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    // Write the choice *first*, then flip the completion flag. If the second
    // write fails we simply re-run onboarding; the reverse order would leave us
    // "onboarded" with no instrument, silently falling back to `Everything`.
    await prefs.setString(_kFilter, filter.name);
    await prefs.setBool(_kOnboarded, true);
  }

  // --- In-progress session draft (crash/kill recovery) ---

  Future<void> saveSessionDraft(SessionDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDraftExercise, draft.exerciseId);
    await prefs.setInt(
      _kDraftStartedAt,
      draft.startedAt.millisecondsSinceEpoch,
    );
    await prefs.setInt(_kDraftElapsed, draft.elapsedSeconds);
  }

  Future<SessionDraft?> readSessionDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final exerciseId = prefs.getString(_kDraftExercise);
    final startedAtMs = prefs.getInt(_kDraftStartedAt);
    if (exerciseId == null || startedAtMs == null) return null;
    return SessionDraft(
      exerciseId: exerciseId,
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
      elapsedSeconds: prefs.getInt(_kDraftElapsed) ?? 0,
    );
  }

  Future<void> clearSessionDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftExercise);
    await prefs.remove(_kDraftStartedAt);
    await prefs.remove(_kDraftElapsed);
  }

  /// Clears everything — used by dev tooling and tests.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnboarded);
    await prefs.remove(_kFilter);
    await clearSessionDraft();
  }
}
