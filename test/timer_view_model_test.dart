import 'package:flutter_test/flutter_test.dart';
import 'package:practice_tracker/data/settings_service.dart';
import 'package:practice_tracker/models/exercise.dart';
import 'package:practice_tracker/viewmodels/timer_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime clock;
  DateTime now() => clock;
  final exercise = kExercises.first;

  setUp(() {
    clock = DateTime(2026, 7, 12, 10, 0, 0);
    SharedPreferences.setMockInitialValues({});
  });

  test('elapsed is derived from the wall clock, not from counting ticks',
      () async {
    final vm = TimerViewModel(FakePracticeRepository(), now: now);
    addTearDown(vm.dispose);

    vm.selectExercise(exercise);
    vm.start();
    expect(vm.status, TimerStatus.running);

    // 90s of real time pass while the UI thread was frozen (lock/background):
    // no ticks fired, yet the count must reflect reality on resume.
    clock = clock.add(const Duration(seconds: 90));
    vm.refreshFromClock();
    expect(vm.elapsed, const Duration(seconds: 90));

    vm.stop();
    expect(vm.status, TimerStatus.review);
    expect(vm.elapsed, const Duration(seconds: 90));
  });

  test('a second start() is a no-op and does not reset the start time',
      () async {
    final vm = TimerViewModel(FakePracticeRepository(), now: now);
    addTearDown(vm.dispose);

    vm.selectExercise(exercise);
    vm.start();
    clock = clock.add(const Duration(seconds: 30));
    vm.start(); // ignored while running
    vm.refreshFromClock();
    expect(vm.elapsed, const Duration(seconds: 30));
  });

  test('stopping with zero elapsed returns to idle', () {
    final vm = TimerViewModel(FakePracticeRepository(), now: now);
    addTearDown(vm.dispose);

    vm.selectExercise(exercise);
    vm.start();
    vm.stop(); // no time passed
    expect(vm.status, TimerStatus.idle);
  });

  test('save persists the reviewed session', () async {
    final vm = TimerViewModel(FakePracticeRepository(), now: now);
    addTearDown(vm.dispose);

    vm.selectExercise(exercise);
    vm.start();
    clock = clock.add(const Duration(seconds: 120));
    vm.stop();

    final saved = await vm.save('metronome 80bpm');
    expect(saved, isNotNull);
    expect(saved!.durationSeconds, 120);
    expect(saved.exerciseId, exercise.id);
    expect(vm.error, isNull);
    expect(vm.saving, isFalse);
  });

  test('a save failure keeps the review state and surfaces the error',
      () async {
    final vm = TimerViewModel(ThrowingPracticeRepository(), now: now);
    addTearDown(vm.dispose);

    vm.selectExercise(exercise);
    vm.start();
    clock = clock.add(const Duration(seconds: 120));
    vm.stop();

    final saved = await vm.save('x');
    expect(saved, isNull);
    expect(vm.error, isNotNull);
    expect(vm.status, TimerStatus.review, reason: 'so the user can retry');
    expect(vm.elapsed, const Duration(seconds: 120));
    expect(vm.saving, isFalse);
  });

  test('an interrupted session is recovered from the persisted draft',
      () async {
    SharedPreferences.setMockInitialValues({
      'draft_exercise_id': exercise.id,
      'draft_started_at': DateTime(2026, 7, 12, 9).millisecondsSinceEpoch,
      'draft_elapsed_seconds': 300,
    });

    final vm = TimerViewModel(
      FakePracticeRepository(),
      settings: SettingsService(),
      now: now,
    );
    addTearDown(vm.dispose);

    // Let the async restore in the constructor complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(vm.restoredFromDraft, isTrue);
    expect(vm.status, TimerStatus.review);
    expect(vm.elapsed, const Duration(seconds: 300));
    expect(vm.exercise?.id, exercise.id);
  });
}
