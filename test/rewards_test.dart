import 'package:flutter_test/flutter_test.dart';
import 'package:practice_tracker/models/rewards.dart';

void main() {
  test('beats accrue at 10 per minute', () {
    expect(beatsFromSeconds(0), 0);
    expect(beatsFromSeconds(60), 10);
    expect(beatsFromSeconds(3600), 600);
    expect(beatsForExtraMinutes(10), 100);
  });

  test('nextTierAfter returns the first unreached tier', () {
    expect(nextTierAfter(0)?.name, 'Warm-up Badge');
    expect(nextTierAfter(600)?.name, 'Consistency Crown');
    expect(nextTierAfter(1000000), isNull); // everything unlocked
  });
}
