import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/settings_service.dart';
import '../models/instrument.dart';

/// Top-level app state: is onboarding done, and which instrument is tracked.
/// Decides whether the root shows onboarding or the home shell.
class AppViewModel extends ChangeNotifier {
  AppViewModel(this._settings) {
    unawaited(_load());
  }

  final SettingsService _settings;

  bool _loading = true;
  bool _onboarded = false;
  InstrumentFilter _filter = InstrumentFilter.all;

  bool get loading => _loading;
  bool get onboarded => _onboarded;
  InstrumentFilter get filter => _filter;

  Future<void> _load() async {
    _onboarded = await _settings.isOnboarded();
    _filter = await _settings.instrumentFilter();
    _loading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding(InstrumentFilter filter) async {
    await _settings.completeOnboarding(filter);
    _filter = filter;
    _onboarded = true;
    notifyListeners();
  }
}
