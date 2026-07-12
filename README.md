# Practice Tracker

A focused practice timer for guitarists and bassists. Pick a daily exercise,
run a lifecycle-safe timer, and watch a weekly report and a Beats reward system
turn "I should practice more" into a visible habit.

Built with Flutter, offline-first (SQLite), no account required.

> Status: MVP. Architecture is production-shaped; see the roadmap for what's
> left before a store release.

## Screenshots

<!-- TODO: add screenshots / GIF (onboarding → practice → weekly report). -->

## Why this exists

Most practice apps are either heavy metronome suites or generic habit trackers.
Practice Tracker does one thing: make a short daily practice session frictionless
to start and satisfying to look back on — tuned to how string players actually
warm up (chromatics, picking, scales, arpeggios, groove).

## Features

- **One-tap practice timer** with a curated per-instrument exercise catalogue.
- **Weekly report** — per-exercise totals for the current calendar week.
- **Beats reward tiers** — lifetime practice time unlocks tiers, for momentum.
- **Onboarding** that picks the instrument (guitar / bass / everything).
- **Crash-safe sessions** — an in-progress session survives the app being
  killed and is offered back for Save/Discard on the next launch.
- **Offline-first** — everything is local SQLite; no sign-in, no network.

## Architecture

MVVM with a clear data-layer boundary, so the UI never talks to SQLite directly
and storage can be swapped without touching screens.

```
lib/
  models/       # immutable value objects (PracticeSession, Exercise, …)
  data/         # DatabaseService (sqflite), PracticeRepository (interface + impl),
                # SettingsService (SharedPreferences)
  viewmodels/   # ChangeNotifier VMs (Timer, Report, Rewards, App)
  ui/           # screens + widgets
  theme/        # design tokens
  utils/        # formatting helpers
```

- **UI → ViewModel → Repository → SQLite.** ViewModels depend on the
  `PracticeRepository` *interface*, not on sqflite — a fake is injected in tests.
- **Dependency injection** via `provider`, wired once in `main.dart`.
- **Testable clocks** — the timer and report take an injectable `DateTime Function()`
  so time-dependent logic is deterministic under test.

### Reliability decisions worth calling out

- **The timer derives elapsed time from a wall-clock start timestamp**, not from
  counting ticks. A `Timer.periodic` only nudges the UI; a dropped, late, or
  backgrounded tick can't make the count drift. Practice keeps counting while the
  app is backgrounded/locked, and is recomputed from the clock on resume.
- **Database migrations are incremental** (`if (oldVersion < N)`) and preserve
  existing rows — no future schema bump wipes practice history.
- **Save/load paths use `try/finally`** with surfaced error state and Retry, so a
  failed write never strands the UI in a stuck spinner or disabled button.

## Tech stack

| Concern        | Choice                          |
|----------------|---------------------------------|
| Framework      | Flutter (Dart 3)                |
| State          | `provider` + `ChangeNotifier`   |
| Local storage  | `sqflite` (SQLite)              |
| Preferences    | `shared_preferences`            |
| Fonts          | `google_fonts` (Space Grotesk)  |
| Tests          | `flutter_test`, `sqflite_common_ffi` (real engine, not a mock) |

## Running the project

```bash
flutter pub get
flutter run            # pick a device, or run on Chrome/macOS for a quick look
```

## Testing

```bash
flutter analyze        # static analysis (clean)
flutter test           # unit + widget tests
```

Tests cover the timer state machine (including background/resume and save
failure), the calendar-week report aggregation, reward-tier math, the SQLite
repository against a real engine, and the v2→v3 migration preserving data.

## Roadmap

- [ ] Reminders / practice notifications (habit retention).
- [ ] Per-session history with edit/delete and manual (after-the-fact) entry.
- [ ] Cloud backup / sync so a lost phone isn't a lost streak.
- [ ] App icon, splash screen, and Play Store release setup.
- [ ] Bundled font for offline-first startup.
- [ ] On-device performance pass (animated background battery/GPU).

## MVP limitations

- Data is local only — no backup/sync yet.
- No pause (Stop → review); no manual back-dated entry yet.
- Monetization (paywall) is not wired.
