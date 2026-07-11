import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/rewards.dart';
import '../../theme/app_theme.dart';
import '../../utils/duration_format.dart';
import '../../viewmodels/rewards_view_model.dart';

/// Rewards tab: Beats balance, progress to the next tier, and the reward ladder.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rewards = context.watch<RewardsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: RefreshIndicator(
        onRefresh: rewards.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _BeatsHeader(rewards: rewards),
            const SizedBox(height: 28),
            Text(
              'REWARD LADDER',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppColors.violet, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            for (final tier in kRewardTiers)
              _TierRow(tier: tier, unlocked: rewards.isUnlocked(tier)),
          ],
        ),
      ),
    );
  }
}

class _BeatsHeader extends StatelessWidget {
  const _BeatsHeader({required this.rewards});

  final RewardsViewModel rewards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = rewards.nextTier;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.violetDeep.withValues(alpha: 0.55),
            AppColors.magenta.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('🎵', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Text(
                '${rewards.beats}',
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text('Beats',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${rewards.totalTime.compact} practiced all-time',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          if (next != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rewards.progressToNext,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${next.beats - rewards.beats} Beats to ${next.emoji} ${next.name}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.tier, required this.unlocked});

  final RewardTier tier;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? AppColors.violet : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.4,
              child: Text(tier.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: unlocked ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    '🎵 ${tier.beats}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            Icon(
              unlocked ? Icons.check_circle : Icons.lock_outline,
              color: unlocked ? AppColors.violet : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}
