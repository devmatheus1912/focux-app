import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_input.dart';

void main() {
  test('prescription range is not editable seed', () {
    expect(checkinIsPrescriptionRange('8-12'), isTrue);
    expect(checkinIsPrescriptionRange('8 – 12'), isTrue);
    expect(checkinIsPrescriptionRange('10'), isFalse);
    expect(
      checkinSerieRepsSeed(serieRepeticoes: null, prescricacao: '8-12'),
      '',
    );
    expect(
      checkinSerieRepsSeed(serieRepeticoes: '8-12', prescricacao: '8-12'),
      '',
    );
    expect(
      checkinSerieRepsSeed(serieRepeticoes: '15', prescricacao: '8-12'),
      '15',
    );
    expect(
      checkinSeriePrescricaoHint('8-12'),
      'Prescrição do personal: 8-12',
    );
  });
}
