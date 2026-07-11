import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../models/rewards.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_format.dart';
import '../../viewmodels/app_view_model.dart';
import '../widgets/exercise_visuals.dart';
import '../widgets/weekly_report.dart';

/// Shown right after a session is saved: what you just did, Beats earned, and
/// this week's coverage graph so the gaps are front-and-centre.
class SessionReportScreen extends StatelessWidget {
  const SessionReportScreen({
    super.key,
    required this.exercise,
    required this.duration,
  });

  final Exercise exercise;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = context.read<AppViewModel>().filter;
    final beatsEarned = beatsFromSeconds(duration.inSeconds);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Session complete'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SessionVerdict(duration: duration),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(iconForExercise(exercise.id),
                      color: AppColors.violet, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${exercise.name}  ·  ${duration.compact}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.violetDeep.withValues(alpha: 0.5),
                      AppColors.magenta.withValues(alpha: 0.35),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Text('🎵', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('+$beatsEarned Beats',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text('earned this session',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'YOUR WEEK',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.violet,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What you played — and where the gaps still are.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 16),
              WeeklyReport(filter: filter),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How seriously to take a session, by how long it ran. Short sessions get
/// teased rather than praised — this doubles as protection against someone
/// tapping start/stop just to farm the "Nice work" screen.
enum _Effort { tooShort, medium, solid }

_Effort _effortFor(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds <= 300) return _Effort.tooShort; // ≤ 5:00
  if (seconds <= 600) return _Effort.medium; // 5:01–10:00
  return _Effort.solid; // > 10:00
}

/// The reactive header on the session-complete screen. For the middle tier it
/// asks whether the user was distracted, then reacts to their answer.
class _SessionVerdict extends StatefulWidget {
  const _SessionVerdict({required this.duration});

  final Duration duration;

  @override
  State<_SessionVerdict> createState() => _SessionVerdictState();
}

class _SessionVerdictState extends State<_SessionVerdict> {
  bool? _wasScrolling; // null until the middle-tier question is answered

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effort = _effortFor(widget.duration);

    String title;
    String subtitle;
    Widget? actions;

    switch (effort) {
      case _Effort.tooShort:
        title = 'Done already? 🤨';
        subtitle =
            "That barely counts as a warm-up. A real session is just getting "
            'started — come back and give it a proper go.';
      case _Effort.solid:
        title = 'Nice work! 🎉';
        subtitle = "That's how the gaps close. Keep showing up like that.";
      case _Effort.medium:
        if (_wasScrolling == null) {
          title = 'Not bad 👀';
          subtitle =
              "You could've gone a little longer. And be honest — were you "
              'scrolling your phone the whole time?';
          actions = Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _wasScrolling = true),
                  child: const Text('Yeah, I was'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _wasScrolling = false),
                  child: const Text('No, locked in'),
                ),
              ),
            ],
          );
        } else if (_wasScrolling == false) {
          title = 'Haha — just kidding 😄';
          subtitle = 'Respect. Keep that focus and the gaps close fast.';
        } else {
          title = 'Yeah… I figured 😐';
          subtitle =
              'Progress depends entirely on your focus. Be here while '
              "you're here — the timer only counts, it can't concentrate for you.";
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        if (actions != null) ...[
          const SizedBox(height: 16),
          actions,
        ],
      ],
    );
  }
}
