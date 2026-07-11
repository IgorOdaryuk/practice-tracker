import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/instrument.dart';
import '../../viewmodels/app_view_model.dart';
import 'instrument_select_screen.dart';
import 'welcome_screen.dart';

/// Two-page onboarding: welcome pitch → instrument choice. Finishing writes the
/// choice to settings, which flips the root over to the home shell.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish(InstrumentFilter filter) {
    return context.read<AppViewModel>().completeOnboarding(filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            WelcomeScreen(onNext: _next),
            InstrumentSelectScreen(onDone: _finish),
          ],
        ),
      ),
    );
  }
}
