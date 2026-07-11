import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../models/rewards.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_format.dart';
import '../../viewmodels/app_view_model.dart';
import '../../viewmodels/report_view_model.dart';
import '../../viewmodels/rewards_view_model.dart';
import '../../viewmodels/timer_view_model.dart';
import '../report/session_report_screen.dart';
import '../widgets/beats_pill.dart';
import '../widgets/exercise_visuals.dart';

/// Practice tab: pick an exercise, run the timer, save → session report.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Default to the first exercise for the chosen instrument.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timer = context.read<TimerViewModel>();
      if (timer.exercise == null) {
        final list = exercisesFor(context.read<AppViewModel>().filter);
        if (list.isNotEmpty) timer.selectExercise(list.first);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _changeExercise() async {
    final timer = context.read<TimerViewModel>();
    final list = exercisesFor(context.read<AppViewModel>().filter);
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: const Color(0xFF1B0F38),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final exercise in list)
              ListTile(
                leading: Icon(iconForExercise(exercise.id),
                    color: AppColors.violet),
                title: Text(exercise.name),
                subtitle: Text(exercise.blurb),
                trailing: exercise.id == timer.exercise?.id
                    ? const Icon(Icons.check, color: AppColors.violet)
                    : null,
                onTap: () => Navigator.pop(context, exercise),
              ),
          ],
        ),
      ),
    );
    if (picked != null) timer.selectExercise(picked);
  }

  Future<void> _handleStop() async {
    final timer = context.read<TimerViewModel>();
    final confirmedStop = await _showStopNudge(context);
    if (confirmedStop == true) timer.stop();
  }

  Future<void> _save() async {
    if (_submitting) return;
    // Capture everything that needs `context` before any await, so we never
    // touch a possibly-unmounted context across an async gap.
    final timer = context.read<TimerViewModel>();
    final report = context.read<ReportViewModel>();
    final rewards = context.read<RewardsViewModel>();
    final navigator = Navigator.of(context);
    final exercise = timer.exercise;

    // Keep the button in its loading state for the whole operation so the
    // review UI never flickers back to idle before the report appears.
    setState(() => _submitting = true);

    final saved = await timer.save(_noteController.text);
    if (saved == null || exercise == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    await report.load();
    await rewards.load();
    if (!mounted) return;

    _noteController.clear();
    // Reset to idle now, then push in the same frame: the report screen covers
    // the transition, so the underlying screen shows a clean idle state (never
    // a half-reset review) both on the way in and on the way back.
    timer.reset();
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => SessionReportScreen(
          exercise: exercise,
          duration: saved.duration,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerViewModel>();
    final theme = Theme.of(context);
    final exercise = timer.exercise;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        actions: const [BeatsPill()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (exercise != null)
                _ExerciseCard(
                  exercise: exercise,
                  canChange: timer.status == TimerStatus.idle,
                  onChange: _changeExercise,
                ),
              const Spacer(),
              Text(
                timer.elapsed.clock,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w700,
                  fontSize: 72,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                switch (timer.status) {
                  TimerStatus.idle => 'Ready when you are',
                  TimerStatus.running => 'Keep going 🔥',
                  TimerStatus.review => timer.elapsed.inSeconds <= 600
                      ? 'Are you serious? 🤨'
                      : 'Nice — log it below',
                },
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.white60),
              ),
              const Spacer(),
              _Controls(
                timer: timer,
                noteController: _noteController,
                submitting: _submitting,
                onStop: _handleStop,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "are you sure?" nudge. Returns true if the user still wants to stop.
Future<bool?> _showStopNudge(BuildContext context) {
  final bonus = beatsForExtraMinutes(10);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1B0F38),
      title: const Text('Stopping already?'),
      content: Text(
        'Practice 10 more minutes and bank +$bonus Beats 🔥\n'
        'The gaps close faster when you push a little longer.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep going'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Stop'),
        ),
      ],
    ),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.canChange,
    required this.onChange,
  });

  final Exercise exercise;
  final bool canChange;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(iconForExercise(exercise.id),
                color: AppColors.violet, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.blurb,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            if (canChange)
              TextButton(onPressed: onChange, child: const Text('Change')),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.timer,
    required this.noteController,
    required this.submitting,
    required this.onStop,
    required this.onSave,
  });

  final TimerViewModel timer;
  final TextEditingController noteController;
  final bool submitting;
  final VoidCallback onStop;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    switch (timer.status) {
      case TimerStatus.idle:
        return FilledButton.icon(
          onPressed: timer.exercise == null ? null : timer.start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        );
      case TimerStatus.running:
        return FilledButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
        );
      case TimerStatus.review:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: noteController,
              enabled: !submitting,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'What did you work on?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: submitting ? null : timer.discard,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: submitting ? null : onSave,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save session'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
