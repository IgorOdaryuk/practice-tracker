import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/rewards_view_model.dart';

/// Small "🎵 1,234" balance chip, shown in app bars.
class BeatsPill extends StatelessWidget {
  const BeatsPill({super.key});

  @override
  Widget build(BuildContext context) {
    final beats = context.watch<RewardsViewModel>().beats;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.violetDeep.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎵', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            '$beats',
            style: const TextStyle(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
