import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/engajamento_display.dart';

void main() {
  test('engajamentoPeriodoLabel e janelas', () {
    expect(engajamentoPeriodos, [30, 60, 90]);
    expect(engajamentoPeriodoLabel(30), '30 dias');
    expect(engajamentoPeriodoLabel(90), '90 dias');
  });

  test('engajamentoTipoLabel em PT-BR', () {
    expect(engajamentoTipoLabel('TREINO'), 'Treino');
    expect(engajamentoTipoLabel('treino_iniciado'), 'Treino');
    expect(engajamentoTipoLabel('CHECKIN_CONCLUIDO'), 'Check-in');
    expect(engajamentoTipoLabel('MEDIDA'), 'Medida');
    expect(engajamentoTipoLabel('MENSAGEM'), 'Mensagem');
    expect(engajamentoTipoLabel(''), 'Evento');
    expect(engajamentoTipoLabel(null), 'Evento');
    expect(engajamentoTipoLabel('CUSTOM'), 'CUSTOM');
  });

  test('engajamentoFxIcon por tipo', () {
    expect(engajamentoFxIcon('TREINO'), 'dumbbell');
    expect(engajamentoFxIcon('CHECKIN_CONCLUIDO'), 'dumbbell');
    expect(engajamentoFxIcon('MEDIDA'), 'trend');
    expect(engajamentoFxIcon('MENSAGEM'), 'chat');
    expect(engajamentoFxIcon(null), 'calendar');
  });

  test('engajamentoWhenLabel formata ISO', () {
    expect(engajamentoWhenLabel('2026-09-01T14:05:00'), '01/09 14:05');
    expect(engajamentoWhenLabel(''), '—');
    expect(engajamentoWhenLabel('nao-e-data'), 'nao-e-data');
  });

  test('engajamentoEventoLabel e subtitle', () {
    expect(engajamentoEventoLabel('  Treino A - CONCLUIDO  ', 'TREINO'),
        'Treino A - CONCLUIDO');
    expect(engajamentoEventoLabel('  ', 'MEDIDA'), 'Medida');
    expect(
      engajamentoEventoSubtitle(
        tipo: 'TREINO',
        dataHora: '2026-09-01T14:05:00',
      ),
      'Treino · 01/09 14:05',
    );
  });

  test('engajamentoHubSubtitle junta nome e período', () {
    expect(
      engajamentoHubSubtitle(alunoNome: 'Ana', dias: 30),
      'Ana · 30 dias',
    );
    expect(
      engajamentoHubSubtitle(alunoNome: '  ', dias: 60),
      'Aluno · 60 dias',
    );
  });

  test('engajamentoEventosMetricHint', () {
    expect(engajamentoEventosMetricHint(0, 30), 'Nada em 30 dias');
    expect(engajamentoEventosMetricHint(4, 90), '90 dias');
  });

  test('engajamento agrega tipos e rota de próxima ação', () {
    final eventos = [
      EventoEngajamento(
        tipo: 'TREINO',
        descricao: 'A',
        dataHora: '2026-09-01T10:00:00',
      ),
      EventoEngajamento(
        tipo: 'MENSAGEM',
        descricao: 'Oi',
        dataHora: '2026-09-02T11:00:00',
      ),
      EventoEngajamento(
        tipo: 'CHECKIN_CONCLUIDO',
        descricao: 'B',
        dataHora: '2026-09-03T12:00:00',
      ),
    ];
    expect(engajamentoTreinosCount(eventos), 2);
    expect(engajamentoMensagensCount(eventos), 1);
    expect(engajamentoUltimoHint(eventos), 'Check-in · 03/09 12:00');
    expect(engajamentoUltimoValue(eventos), 'Check-in');
    expect(engajamentoUltimoValue(const []), '—');
    expect(engajamentoEventoRota('MENSAGEM', 9), '/alunos/9/chat');
    expect(engajamentoEventoRota('MEDIDA', 9), '/alunos/9/evolucao');
    expect(engajamentoEventoRota('TREINO', 9), '/alunos/9/treinos-list');
    expect(engajamentoEventoRota('OUTRO', 9), isNull);
  });
}
