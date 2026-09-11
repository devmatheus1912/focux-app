import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('RPE plain labels help students who do not know the acronym', () {
    expect(checkinRpePlainLabel(2), 'Muito leve');
    expect(checkinRpePlainLabel(7), 'Cansativo');
    expect(checkinRpePlainLabel(10), 'No limite');
    expect(checkinRpeValueLine(8), '8 · Pesado');
    expect(checkinRpeSectionTitle, contains('Esforço'));
    expect(checkinRpeSectionHint, contains('não é quantidade de reps'));
    expect(checkinRpeAlvoHint(7), contains('Cansativo'));
  });

  test('RPE first-use hint is consumed once via SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    expect(checkinRpeHintSeenKey, 'checkin_rpe_hint_seen_v1');
    expect(await checkinConsumeRpeFirstUseHint(), isTrue);
    expect(await checkinConsumeRpeFirstUseHint(), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(checkinRpeHintSeenKey), isTrue);
  });
}
