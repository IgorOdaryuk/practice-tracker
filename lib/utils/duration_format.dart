/// Formatting helpers for [Duration] values shown in the UI.
extension DurationFormat on Duration {
  /// `H:MM:SS` for the live timer (hours only when non-zero), e.g. `4:07` or
  /// `1:02:09`.
  String get clock {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$minutes:$ss';
  }

  /// Compact human label for lists/totals, e.g. `1h 05m`, `12m 30s`, `45s`.
  String get compact {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }
}
