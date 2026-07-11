import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// First onboarding page — the pitch. Short, and aimed at the real pain:
/// players repeat what's comfortable and never see what they skip.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRACTICE TRACKER',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.violet,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You practice.\nBut do you know what\nyou keep skipping?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 32),
          const _PitchPoint(
            emoji: '🎯',
            text: 'Time every session in a single tap.',
          ),
          const _PitchPoint(
            emoji: '📊',
            text:
                'Every 7 days, a visual report shows what you played — and the '
                'gaps you keep avoiding.',
          ),
          const _PitchPoint(
            emoji: '🔥',
            text: 'Earn Beats for every minute and unlock rewards as you grow.',
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Your first week is on us — every feature unlocked. Give it 30 '
              'days and watch the gaps disappear.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text('Get started'),
          ),
        ],
      ),
    );
  }
}

class _PitchPoint extends StatelessWidget {
  const _PitchPoint({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
