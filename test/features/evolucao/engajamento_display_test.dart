import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/engajamento_display.dart';

void main() {

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



  EventoEngajamento treino(String dataHora, [String? status]) =>
      EventoEngajamento(
        tipo: 'TREINO',
        descricao: 'A',
        dataHora: dataHora,
        status: status,
      );


  test('frase responde se o aluno está firme', () {
    final now = DateTime(2026, 9, 10, 18);
    expect(engajamentoFrase(const [], now: now), contains('Nenhum treino'));
    expect(
      engajamentoFrase([
        treino('2026-09-09T10:00:00', 'CONCLUIDO'),
        treino('2026-09-05T10:00:00', 'CONCLUIDO'),
      ], now: now),
      'Treinou 2 vezes nos últimos 7 dias. Último treino ontem.',
    );
    expect(
      engajamentoFrase([treino('2026-08-20T10:00:00', 'CONCLUIDO')], now: now),
      'Não treinou nos últimos 7 dias. Último treino há 21 dias.',
    );
  });

  test('calendário: feito vence cancelado no mesmo dia', () {
    final now = DateTime(2026, 9, 10, 18);
    final dias = engajamentoCalendario([
      treino('2026-09-10T08:00:00', 'CANCELADO'),
      treino('2026-09-10T09:00:00', 'CONCLUIDO'),
      treino('2026-09-09T09:00:00', 'CANCELADO'),
    ], now: now);
    expect(dias, hasLength(35));
    expect(dias.last.dia, DateTime(2026, 9, 10));
    expect(dias.last.estado, EngajamentoTreinoEstado.feito);
    expect(dias[33].estado, EngajamentoTreinoEstado.cancelado);
    expect(dias.first.estado, isNull);
  });


  test('conversa avisa quando o aluno falou por último', () {
    final now = DateTime(2026, 9, 10, 18);
    EventoEngajamento msg(String dataHora, String remetente) =>
        EventoEngajamento(
          tipo: 'MENSAGEM',
          descricao: 'x',
          dataHora: dataHora,
          remetente: remetente,
        );
    expect(engajamentoConversa(const [], now: now), isNull);
    final semResposta = engajamentoConversa([
      msg('2026-09-08T10:00:00', 'ALUNO'),
      msg('2026-09-07T10:00:00', 'PERSONAL'),
    ], now: now);
    expect(semResposta?.semResposta, isTrue);
    expect(semResposta?.texto, 'Última mensagem do aluno há 2 dias.');
    expect(
      engajamentoConversa([
        msg('2026-09-09T10:00:00', 'PERSONAL'),
        msg('2026-09-08T10:00:00', 'ALUNO'),
      ], now: now)?.semResposta,
      isFalse,
    );
  });


  test('rota de próxima ação', () {
    expect(engajamentoEventoRota('MENSAGEM', 9), '/alunos/9/chat');
    expect(engajamentoEventoRota('MEDIDA', 9), '/alunos/9/evolucao');
    expect(engajamentoEventoRota('TREINO', 9), '/alunos/9/rotina');
    expect(engajamentoEventoRota('OUTRO', 9), isNull);
  });
}
