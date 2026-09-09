import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/anamnese/data/anamnese_repository.dart';
import 'package:focux_app/features/anamnese/utils/anamnese_display.dart';

void main() {
  test('anamneseNivelLabel e nulo', () {
    expect(anamneseNivelLabel('SEDENTARIO'), 'Sedentário');
    expect(anamneseNivelLabel('MUITO_INTENSO'), 'Muito intenso');
    expect(anamneseNivelLabel(null), 'Selecionar');
    expect(anamneseNivelOuNulo('LEVE'), 'LEVE');
    expect(anamneseNivelOuNulo('x'), isNull);
  });

  test('anamneseDisponibilidade', () {
    expect(anamneseDisponibilidadeLabel(1), '1 dia por semana');
    expect(anamneseDisponibilidadeLabel(3), '3 dias por semana');
    expect(anamneseDisponibilidadeClamp(null), 3);
    expect(anamneseDisponibilidadeClamp(0), 1);
    expect(anamneseDisponibilidadeClamp(9), 7);
  });

  test('métricas do hub personal', () {
    final a = Anamnese(
      status: AnamneseStatus.preenchida,
      parqCompleto: true,
      parqPositivo: true,
      alertas: const ['Dor no peito'],
      disponibilidadeSemanal: 4,
    );
    expect(anamneseParqMetricValue(a), 'Atenção');
    expect(anamneseAlertasMetricValue(a), '1');
    expect(anamneseDispMetricValue(a), '4 dias por semana');
    expect(anamneseDetalheSecoes, hasLength(4));
  });

  test('status labels e flags', () {
    expect(anamneseStatusLabel(AnamneseStatus.solicitada), 'Solicitada');
    expect(anamneseStatusLabel(AnamneseStatus.precisaAtestado), 'Precisa atestado');
    expect(anamneseBoolLabel(true), 'Sim');
    expect(anamneseBoolLabel(false), 'Não');
    expect(anamneseBoolLabel(null), '—');

    final solicitada = Anamnese(status: AnamneseStatus.solicitada);
    expect(solicitada.alunoDevePreencher, isTrue);
    expect(solicitada.personalPodeRevisar, isFalse);

    final preenchida = Anamnese(status: AnamneseStatus.preenchida);
    expect(preenchida.alunoDevePreencher, isFalse);
    expect(preenchida.personalPodeRevisar, isTrue);
  });

  test('fromJson mapeia contrato novo', () {
    final a = Anamnese.fromJson({
      'status': 'PREENCHIDA',
      'parqPositivo': true,
      'parqCompleto': true,
      'alertas': ['PAR-Q+', 'CV'],
      'parqCondicaoCardiaca': true,
      'parqDorPeitoAtividade': false,
      'sonoHoras': '7.5',
      'historicoAtividade': 'Musculação 2 anos',
      'algoMais': 'Prefiro noite',
      'notasProfissional': 'Ok',
    });
    expect(a.status, AnamneseStatus.preenchida);
    expect(a.parqPositivo, isTrue);
    expect(a.alertas, ['PAR-Q+', 'CV']);
    expect(a.parqCondicaoCardiaca, isTrue);
    expect(a.sonoHoras, 7.5);
    expect(a.historicoAtividade, 'Musculação 2 anos');
    expect(anamneseParqValue(a, 'parqCondicaoCardiaca'), isTrue);
  });
}
