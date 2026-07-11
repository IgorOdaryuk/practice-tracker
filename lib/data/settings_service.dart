import 'package:shared_preferences/shared_preferences.dart';

import '../models/instrument.dart';

/// Small persisted-preferences wrapper (onboarding flag + chosen instrument).
class SettingsService {
  static const String _kOnboarded = 'onboarding_complete';
  static const String _kFilter = 'instrument_filter';

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
    await prefs.setBool(_kOnboarded, true);
    await prefs.setString(_kFilter, filter.name);
  }

  /// Clears everything — used by dev tooling and tests.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnboarded);
    await prefs.remove(_kFilter);
  }
}
