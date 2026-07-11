/// A physical instrument the app has exercises for.
enum Instrument {
  guitar,
  bass;

  String get label => switch (this) {
        Instrument.guitar => 'Guitar',
        Instrument.bass => 'Bass',
      };
}

/// What the user chose to track. `all` covers every instrument.
enum InstrumentFilter {
  guitar,
  bass,
  all;

  String get label => switch (this) {
        InstrumentFilter.guitar => 'Guitar',
        InstrumentFilter.bass => 'Bass',
        InstrumentFilter.all => 'Everything',
      };

  bool includes(Instrument instrument) => switch (this) {
        InstrumentFilter.guitar => instrument == Instrument.guitar,
        InstrumentFilter.bass => instrument == Instrument.bass,
        InstrumentFilter.all => true,
      };

  static InstrumentFilter fromName(String name) =>
      InstrumentFilter.values.firstWhere(
        (f) => f.name == name,
        orElse: () => InstrumentFilter.all,
      );
}
