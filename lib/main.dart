import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database_service.dart';
import 'data/practice_repository.dart';
import 'data/settings_service.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding/onboarding_flow.dart';
import 'ui/widgets/gradient_background.dart';
import 'viewmodels/app_view_model.dart';
import 'viewmodels/report_view_model.dart';
import 'viewmodels/rewards_view_model.dart';
import 'viewmodels/timer_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  final PracticeRepository repository =
      SqflitePracticeRepository(databaseService);
  final settingsService = SettingsService();

  runApp(
    PracticeTrackerApp(repository: repository, settings: settingsService),
  );
}

class PracticeTrackerApp extends StatelessWidget {
  const PracticeTrackerApp({
    super.key,
    required this.repository,
    required this.settings,
  });

  final PracticeRepository repository;
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PracticeRepository>.value(value: repository),
        ChangeNotifierProvider(create: (_) => AppViewModel(settings)),
        ChangeNotifierProvider(create: (_) => TimerViewModel(repository)),
        ChangeNotifierProvider(create: (_) => ReportViewModel(repository)),
        ChangeNotifierProvider(create: (_) => RewardsViewModel(repository)),
      ],
      child: MaterialApp(
        title: 'Practice Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        themeMode: ThemeMode.dark,
        builder: (context, child) =>
            GradientBackground(child: child ?? const SizedBox.shrink()),
        home: const _Root(),
      ),
    );
  }
}

/// Chooses the first screen once settings have loaded.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppViewModel>();
    if (app.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return app.onboarded ? const HomeScreen() : const OnboardingFlow();
  }
}
