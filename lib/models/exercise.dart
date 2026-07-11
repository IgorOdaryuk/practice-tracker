import 'instrument.dart';

/// A single daily-practice exercise. Immutable, no UI concerns.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.instrument,
    required this.blurb,
  });

  /// Stable key stored on sessions (never renamed).
  final String id;
  final String name;
  final Instrument instrument;

  /// One-line "what it trains".
  final String blurb;
}

/// Static catalogue of exercises recommended to play daily.
///
/// Curated from established teaching sources (Berklee Online, GuitarPlayer,
/// TrueFire, No Treble, Smart Bass Guitar) — not invented.
const List<Exercise> kExercises = [
  // --- Guitar ---
  Exercise(
    id: 'guitar_chromatic',
    name: 'Chromatic Warm-up',
    instrument: Instrument.guitar,
    blurb: '1-2-3-4 across the strings — dexterity & finger independence',
  ),
  Exercise(
    id: 'guitar_picking',
    name: 'Alternate Picking',
    instrument: Instrument.guitar,
    blurb: 'Down-up-down-up — clean, even pick strokes',
  ),
  Exercise(
    id: 'guitar_chords',
    name: 'Chord Transitions',
    instrument: Instrument.guitar,
    blurb: 'Switch between open & barre chords cleanly',
  ),
  Exercise(
    id: 'guitar_scales',
    name: 'Pentatonic & Scales',
    instrument: Instrument.guitar,
    blurb: 'Minor pentatonic and major scale patterns',
  ),
  Exercise(
    id: 'guitar_arps',
    name: 'Arpeggios',
    instrument: Instrument.guitar,
    blurb: 'Chord tones across the fretboard',
  ),

  // --- Bass ---
  Exercise(
    id: 'bass_fingers',
    name: 'Warm-up',
    instrument: Instrument.bass,
    blurb: '1-2-3-4 permutations — loosen up the fretting hand',
  ),
  Exercise(
    id: 'bass_pluck',
    name: 'Plucking Technique',
    instrument: Instrument.bass,
    blurb: 'Alternating fingers & string crossing',
  ),
  Exercise(
    id: 'bass_scales',
    name: 'Scales',
    instrument: Instrument.bass,
    blurb: 'Major & minor — the building blocks',
  ),
  Exercise(
    id: 'bass_arps',
    name: 'Arpeggios',
    instrument: Instrument.bass,
    blurb: 'Chord tones for hand strength & ear',
  ),
  Exercise(
    id: 'bass_groove',
    name: 'Groove & Timing',
    instrument: Instrument.bass,
    blurb: 'Lock to the metronome — feel & pocket',
  ),
];

/// Exercises visible for the chosen [filter], in catalogue order.
List<Exercise> exercisesFor(InstrumentFilter filter) =>
    kExercises.where((e) => filter.includes(e.instrument)).toList();

/// Looks up an exercise by its stored [id], or `null` if unknown.
Exercise? exerciseById(String id) {
  for (final exercise in kExercises) {
    if (exercise.id == id) return exercise;
  }
  return null;
}
