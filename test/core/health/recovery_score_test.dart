import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/health/recovery_score.dart';

void main() {
  test('recovery score rewards sleep and moderate activity', () {
    final view = RecoveryScoreView.compute(
      steps: 9000,
      sleepHours: 8,
      avgHeartRate: 58,
    );

    expect(view.score, greaterThanOrEqualTo(80));
    expect(view.label, 'Pronto para pesar');
  });

  test('recovery score penalizes poor sleep', () {
    final view = RecoveryScoreView.compute(
      steps: 2500,
      sleepHours: 4.5,
      avgHeartRate: 72,
    );

    expect(view.score, lessThan(65));
  });
}
