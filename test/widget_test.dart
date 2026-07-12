import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:practice_tracker/data/settings_service.dart';
import 'package:practice_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Don't hit the network for fonts during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // animateBackground:false keeps the always-on aurora ticker from preventing
  // the tree from ever settling.
  Widget app() => PracticeTrackerApp(
        repository: FakePracticeRepository(),
        settings: SettingsService(),
        animateBackground: false,
      );

  testWidgets('boots into the onboarding welcome screen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('PRACTICE TRACKER'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('a completed onboarding boots straight into the home shell',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'instrument_filter': 'bass',
    });

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Past onboarding: the welcome pitch is gone.
    expect(find.text('PRACTICE TRACKER'), findsNothing);
    expect(find.text('Get started'), findsNothing);
  });
}
