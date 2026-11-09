import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/prescription_volume_stepper.dart';

void main() {
  test('adjustPrescriptionSeries clamps between 1 and 20', () {
    expect(adjustPrescriptionSeries(4, 1), 5);
    expect(adjustPrescriptionSeries(1, -1), 1);
    expect(adjustPrescriptionSeries(20, 1), 20);
  });


  test('parsePrescriptionInt falls back when empty or invalid', () {
    expect(parsePrescriptionInt('', fallback: 4), 4);
    expect(parsePrescriptionInt('  8 ', fallback: 4), 8);
    expect(parsePrescriptionInt('x', fallback: 75), 75);
  });
}
