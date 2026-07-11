import 'package:flutter/material.dart';

import '../../models/instrument.dart';

/// Icon for an exercise by its stable id (UI-layer concern).
IconData iconForExercise(String exerciseId) => switch (exerciseId) {
      'guitar_chromatic' => Icons.straighten,
      'guitar_picking' => Icons.graphic_eq,
      'guitar_chords' => Icons.grid_view,
      'guitar_scales' => Icons.stairs,
      'guitar_arps' => Icons.auto_awesome,
      'bass_fingers' => Icons.back_hand,
      'bass_pluck' => Icons.touch_app,
      'bass_scales' => Icons.stairs,
      'bass_arps' => Icons.auto_awesome,
      'bass_groove' => Icons.av_timer,
      _ => Icons.music_note,
    };

IconData iconForInstrument(Instrument instrument) => switch (instrument) {
      Instrument.guitar => Icons.music_note,
      Instrument.bass => Icons.audiotrack,
    };

IconData iconForFilter(InstrumentFilter filter) => switch (filter) {
      InstrumentFilter.guitar => Icons.music_note,
      InstrumentFilter.bass => Icons.audiotrack,
      InstrumentFilter.all => Icons.library_music,
    };
