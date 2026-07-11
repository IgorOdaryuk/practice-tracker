/// Gamification: "Beats" are the app's currency, earned by practicing.
///
/// Rate: 10 Beats per minute (i.e. 1 Beat per 6 seconds). Kept as a pure
/// function so it's trivially testable and consistent everywhere.
int beatsFromSeconds(int seconds) => seconds ~/ 6;

/// The Beats reward for practicing [minutes] more minutes — used by the
/// "keep going" nudge when the user tries to stop.
int beatsForExtraMinutes(int minutes) => beatsFromSeconds(minutes * 60);

/// A reward the player unlocks by reaching a Beats threshold.
class RewardTier {
  const RewardTier({
    required this.beats,
    required this.name,
    required this.emoji,
  });

  final int beats;
  final String name;
  final String emoji;
}

/// Reward ladder, ascending by cost.
const List<RewardTier> kRewardTiers = [
  RewardTier(beats: 500, name: 'Warm-up Badge', emoji: '🔥'),
  RewardTier(beats: 2000, name: 'Consistency Crown', emoji: '👑'),
  RewardTier(beats: 5000, name: 'Groove Master', emoji: '🎸'),
  RewardTier(beats: 10000, name: 'Stage Ready', emoji: '🎤'),
  RewardTier(beats: 25000, name: 'Virtuoso', emoji: '⭐'),
];

/// First tier the player hasn't reached yet, or `null` if all are unlocked.
RewardTier? nextTierAfter(int beats) {
  for (final tier in kRewardTiers) {
    if (beats < tier.beats) return tier;
  }
  return null;
}
