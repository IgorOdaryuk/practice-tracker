import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/settings_service.dart';
import '../models/instrument.dart';

/// Top-level app state: is onboarding done, and which instrument is tracked.
/// Decides whether the root shows onboarding, the home shell, or an error retry.
class AppViewModel extends ChangeNotifier {
  AppViewModel(this._settings) {
    unawaited(load());
  }

  final SettingsService _settings;

  bool _loading = true;
  Object? _error;
  bool _onboarded = false;
  InstrumentFilter _filter = InstrumentFilter.all;

  bool get loading => _loading;
  Object? get error => _error;
  bool get onboarded => _onboarded;
  InstrumentFilter get filter => _filter;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _onboarded = await _settings.isOnboarded();
      _filter = await _settings.instrumentFilter();
    } catch (error) {
      // Never strand the user on an infinite spinner: surface the error so the
      // root can offer Retry instead of hanging forever.
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding(InstrumentFilter filter) async {
    await _settings.completeOnboarding(filter);
    _filter = filter;
    _onboarded = true;
    notifyListeners();
  }
}
