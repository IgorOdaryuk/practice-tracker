import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../models/instrument.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_format.dart';
import '../../viewmodels/report_view_model.dart';

/// The weekly graph: one horizontal bar per exercise in the chosen instrument's
/// catalogue. Practiced exercises fill proportionally; untouched ones show a
/// "gap" tag so the user sees exactly what they skipped.
class WeeklyReport extends StatelessWidget {
  const WeeklyReport({super.key, required this.filter});

  final InstrumentFilter filter;

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportViewModel>();
    final exercises = exercisesFor(filter);
    final maxSeconds = report.maxSeconds;

    return Column(
      children: [
        for (final exercise in exercises)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: _ExerciseBar(
              name: exercise.name,
              exerciseId: exercise.id,
              seconds: report.secondsFor(exercise.id),
              maxSeconds: maxSeconds,
            ),
          ),
      ],
    );
  }
}

class _ExerciseBar extends StatelessWidget {
  const _ExerciseBar({
    required this.name,
    required this.exerciseId,
    required this.seconds,
    required this.maxSeconds,
  });

  final String name;
  final String exerciseId;
  final int seconds;
  final int maxSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practiced = seconds > 0;
    final fraction = maxSeconds > 0 ? seconds / maxSeconds : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: practiced ? Colors.white : Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (practiced)
              Text(
                Duration(seconds: seconds).compact,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.violet,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const _GapTag(),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 10, width: width, color: Colors.white10),
                  if (practiced)
                    Container(
                      height: 10,
                      width: (width * fraction).clamp(10.0, width),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.barFill),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GapTag extends StatelessWidget {
  const _GapTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gap.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gap.withValues(alpha: 0.5)),
      ),
      child: Text(
        'gap',
        style: TextStyle(
          color: AppColors.gap,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
