import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_input.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final s = SPt();

  test('prescription range is not editable seed', () {
    expect(checkinIsPrescriptionRange('8-12'), isTrue);
    expect(checkinIsPrescriptionRange('8 – 12'), isTrue);
    expect(checkinIsPrescriptionRange('10'), isFalse);
    expect(
      checkinSerieRepsSeed(serieRepeticoes: null, prescricacao: '8-12'),
      '8',
    );
    expect(
      checkinSerieRepsSeed(serieRepeticoes: '8-12', prescricacao: '8-12'),
      '8',
    );
    expect(
      checkinSerieRepsSeed(serieRepeticoes: '15', prescricacao: '8-12'),
      '15',
    );
    expect(
      checkinSeriePrescricaoHint(s, '8-12'),
      'Prescrição do personal: 8-12',
    );
    expect(checkinSeriePrescricaoHint(s, ' '), isNull);
  });

  test('current set prefers last session then prescription', () {
    final previous = ExecucaoSerie(
      id: 1,
      numero: 1,
      cargaKg: 80,
      repeticoes: '9',
    );
    final ee = ExecucaoExercicio(
      id: 1,
      treinoExercicioId: 2,
      exercicioNome: 'Supino',
      series: 3,
      repeticoes: '8-12',
      cargaKg: 20,
      seriesFeitas: 0,
      concluido: false,
      seriesAnteriores: [previous],
    );
    final seed = checkinCurrentSetSeed(ee: ee, numero: 1);
    expect(seed.cargaKg, 80);
    expect(seed.reps, 9);
  });

  test('RPE plain labels help students who do not know the acronym', () {
    expect(checkinRpePlainLabel(s, 2), 'Muito leve');
    expect(checkinRpePlainLabel(s, 7), 'Cansativo');
    expect(checkinRpePlainLabel(s, 10), 'No limite');
    expect(checkinRpeValueLine(s, 8), '8 · Pesado');
    expect(s.checkinRpeTitulo, contains('Esforço'));
    expect(s.checkinRpeHint, contains('não é quantidade de reps'));
    expect(checkinRpeAlvoHint(s, 7), contains('Cansativo'));
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
