import 'package:flutter_test/flutter_test.dart';
import 'package:practice_tracker/models/practice_session.dart';
import 'package:practice_tracker/viewmodels/report_view_model.dart';

import 'fakes.dart';

void main() {
  test('startOfWeek returns local Monday midnight', () {
    final ws = ReportViewModel.startOfWeek(DateTime(2026, 7, 15, 12, 30));
    expect(ws.weekday, DateTime.monday);
    expect(ws.hour, 0);
    expect(ws.minute, 0);
    // Same week: within the 7 days leading up to the input.
    expect(ws.isAfter(DateTime(2026, 7, 8, 12, 30)), isTrue);
    expect(ws.isBefore(DateTime(2026, 7, 15, 12, 31)), isTrue);
  });

  test('load counts only sessions in the current calendar week', () async {
    final now = DateTime(2026, 7, 15, 12); // a Wednesday
    final weekStart = ReportViewModel.startOfWeek(now);
    final repo = FakePracticeRepository();

    // This week (after Monday midnight).
    await repo.addSession(PracticeSession(
      exerciseId: 'bass_groove',
      durationSeconds: 600,
      startedAt: weekStart.add(const Duration(hours: 5)),
    ));
    // Last week — must be excluded even though it's within 7 rolling days
    // would have caught the Sunday before.
    await repo.addSession(PracticeSession(
      exerciseId: 'bass_scales',
      durationSeconds: 999,
      startedAt: weekStart.subtract(const Duration(hours: 2)),
    ));

    final vm = ReportViewModel(repo, now: () => now);
    await vm.load();

    expect(vm.sessionCount, 1);
    expect(vm.secondsFor('bass_groove'), 600);
    expect(vm.secondsFor('bass_scales'), 0);
    expect(vm.total, const Duration(seconds: 600));
  });
}
