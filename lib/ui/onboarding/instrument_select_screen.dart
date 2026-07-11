import 'package:flutter/material.dart';

import '../../models/instrument.dart';
import '../../theme/app_theme.dart';
import '../widgets/exercise_visuals.dart';

/// Second onboarding page — choose what to track.
class InstrumentSelectScreen extends StatefulWidget {
  const InstrumentSelectScreen({super.key, required this.onDone});

  final ValueChanged<InstrumentFilter> onDone;

  @override
  State<InstrumentSelectScreen> createState() => _InstrumentSelectScreenState();
}

class _InstrumentSelectScreenState extends State<InstrumentSelectScreen> {
  InstrumentFilter? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you play?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This sets your daily exercises. You can track everything if you '
            'switch between instruments.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 28),
          for (final filter in InstrumentFilter.values)
            _InstrumentCard(
              filter: filter,
              selected: _selected == filter,
              onTap: () => setState(() => _selected = filter),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _selected == null
                ? null
                : () => widget.onDone(_selected!),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final InstrumentFilter filter;
  final bool selected;
  final VoidCallback onTap;

  String get _subtitle => switch (filter) {
        InstrumentFilter.guitar => 'Warm-ups, picking, chords, scales, arpeggios',
        InstrumentFilter.bass => 'Dexterity, plucking, scales, arpeggios, groove',
        InstrumentFilter.all => 'Every exercise for both instruments',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: selected
            ? AppColors.violetDeep.withValues(alpha: 0.35)
            : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.violet : AppColors.cardBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(iconForFilter(filter), color: AppColors.violet, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filter.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: AppColors.violet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
