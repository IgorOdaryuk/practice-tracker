/// One completed practice session, tied to an exercise by its id.
///
/// Immutable value object; [toMap]/[fromMap] mirror the `sessions` table.
class PracticeSession {
  const PracticeSession({
    this.id,
    required this.exerciseId,
    required this.durationSeconds,
    required this.startedAt,
    this.note = '',
  });

  /// `null` until inserted; assigned by SQLite.
  final int? id;
  final String exerciseId;
  final int durationSeconds;
  final DateTime startedAt;
  final String note;

  Duration get duration => Duration(seconds: durationSeconds);

  PracticeSession copyWith({
    int? id,
    String? exerciseId,
    int? durationSeconds,
    DateTime? startedAt,
    String? note,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'duration_seconds': durationSeconds,
      'started_at': startedAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory PracticeSession.fromMap(Map<String, Object?> map) {
    return PracticeSession(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as String,
      durationSeconds: map['duration_seconds'] as int,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      note: (map['note'] as String?) ?? '',
    );
  }
}
