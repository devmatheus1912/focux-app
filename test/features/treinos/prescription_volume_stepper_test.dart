import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/prescription_volume_stepper.dart';

void main() {
  test('adjustPrescriptionSeries clamps between 1 and 20', () {
    expect(adjustPrescriptionSeries(4, 1), 5);
    expect(adjustPrescriptionSeries(1, -1), 1);
    expect(adjustPrescriptionSeries(20, 1), 20);
  });

  test('adjustPrescriptionRestSeconds moves in 15s steps', () {
    expect(adjustPrescriptionRestSeconds(75, 15), 90);
    expect(adjustPrescriptionRestSeconds(75, -15), 60);
    expect(adjustPrescriptionRestSeconds(10, -15), 15);
    expect(adjustPrescriptionRestSeconds(290, 15), 300);
  });

  test('parsePrescriptionInt falls back when empty or invalid', () {
    expect(parsePrescriptionInt('', fallback: 4), 4);
    expect(parsePrescriptionInt('  8 ', fallback: 4), 8);
    expect(parsePrescriptionInt('x', fallback: 75), 75);
  });
}
