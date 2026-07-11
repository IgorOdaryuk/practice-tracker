import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_format.dart';
import '../../viewmodels/app_view_model.dart';
import '../../viewmodels/report_view_model.dart';
import '../widgets/beats_pill.dart';
import '../widgets/weekly_report.dart';

/// Report tab: this week's coverage graph + a paywall teaser for past weeks.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = context.watch<AppViewModel>().filter;
    final report = context.watch<ReportViewModel>();
    final exercises = exercisesFor(filter);
    final practiced =
        exercises.where((e) => report.secondsFor(e.id) > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('This week'),
        actions: const [BeatsPill()],
      ),
      body: RefreshIndicator(
        onRefresh: report.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _SummaryCard(
              total: report.total,
              sessions: report.sessionCount,
              practiced: practiced,
              totalExercises: exercises.length,
            ),
            const SizedBox(height: 24),
            Text(
              'COVERAGE',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.violet,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'What you played vs. the gaps you skipped.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            WeeklyReport(filter: filter),
            const SizedBox(height: 28),
            const _LockedWeeksCard(),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.sessions,
    required this.practiced,
    required this.totalExercises,
  });

  final Duration total;
  final int sessions;
  final int practiced;
  final int totalExercises;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            _Stat(value: total.compact, label: 'practiced'),
            _divider(),
            _Stat(value: '$sessions', label: 'sessions'),
            _divider(),
            _Stat(value: '$practiced/$totalExercises', label: 'exercises'),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.cardBorder);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _LockedWeeksCard extends StatelessWidget {
  const _LockedWeeksCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.violet),
              const SizedBox(width: 10),
              Text(
                'Unlock all weeks',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The free plan tracks the current week with every feature. Upgrade '
            'to keep your full history and watch progress build week over week.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Upgrade (coming soon)'),
          ),
        ],
      ),
    );
  }
}
