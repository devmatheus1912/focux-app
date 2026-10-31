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

  test('engajamentoEventoLabel e subtitle', () {
    expect(engajamentoEventoLabel('  Treino A - CONCLUIDO  ', 'TREINO'),
        'Treino A · concluído');
    expect(engajamentoEventoLabel('Peito A · em andamento', 'TREINO'),
        'Peito A · em andamento');
    expect(engajamentoEventoLabel('  ', 'MEDIDA'), 'Medida');
    expect(
      engajamentoEventoSubtitle(tipo: 'TREINO', titulo: 'Peito A · concluído'),
      'Treino',
    );
    expect(engajamentoEventoSubtitle(tipo: 'MEDIDA', titulo: 'Medida'), isNull);
  });

  test('engajamento agrupa por dia com hora no trailing', () {
    final now = DateTime(2026, 9, 3, 18);
    expect(engajamentoHoraLabel('2026-09-01T14:05:00'), '14:05');
    expect(engajamentoHoraLabel('x'), '—');
    expect(engajamentoDiaLabel('2026-09-03T08:00:00', now: now), 'Hoje');
    expect(engajamentoDiaLabel('2026-09-02T23:00:00', now: now), 'Ontem');
    expect(engajamentoDiaLabel('2026-08-30T10:00:00', now: now), '30/08');
    final linhas = engajamentoLinhasPorDia([
      EventoEngajamento(tipo: 'TREINO', descricao: 'A', dataHora: '2026-09-03T10:00:00'),
      EventoEngajamento(tipo: 'MENSAGEM', descricao: 'B', dataHora: '2026-09-03T09:00:00'),
      EventoEngajamento(tipo: 'MEDIDA', descricao: 'C', dataHora: '2026-09-02T09:00:00'),
    ], now: now);
    expect(linhas.map((l) => l.dia ?? l.evento!.descricao).toList(),
        ['Hoje', 'A', 'B', 'Ontem', 'C']);
  });

  EventoEngajamento treino(String dataHora, [String? status]) =>
      EventoEngajamento(
        tipo: 'TREINO',
        descricao: 'A',
        dataHora: dataHora,
        status: status,
      );

  test('treino cancelado ou em andamento não conta', () {
    final eventos = [
      treino('2026-09-01T10:00:00', 'CONCLUIDO'),
      treino('2026-09-02T10:00:00', 'CANCELADO'),
      treino('2026-09-02T11:00:00', 'EM_ANDAMENTO'),
      EventoEngajamento(
        tipo: 'TREINO',
        descricao: 'B · cancelado',
        dataHora: '2026-09-02T12:00:00',
      ),
      EventoEngajamento(
        tipo: 'CHECKIN_CONCLUIDO',
        descricao: 'C',
        dataHora: '2026-09-03T12:00:00',
      ),
    ];
    expect(engajamentoTreinosCount(eventos), 2);
    expect(engajamentoCanceladosCount(eventos), 2);
  });

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

  test('parcial aparece no calendário e não conta como treino', () {
    final now = DateTime(2026, 9, 10, 18);
    final eventos = [treino('2026-09-10T08:00:00', 'PARCIAL')];
    expect(engajamentoTreinosCount(eventos), 0);
    expect(
      engajamentoCalendario(eventos, now: now).last.estado,
      EngajamentoTreinoEstado.parcial,
    );
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

  test('atividade junta mensagens do dia e esconde cancelados', () {
    final eventos = [
      EventoEngajamento(
        tipo: 'MENSAGEM',
        descricao: 'Você enviou',
        dataHora: '2026-09-03T11:00:00',
      ),
      EventoEngajamento(
        tipo: 'MENSAGEM',
        descricao: 'Aluno enviou',
        dataHora: '2026-09-03T10:00:00',
      ),
      treino('2026-09-03T09:00:00', 'CANCELADO'),
      treino('2026-09-02T09:00:00', 'CONCLUIDO'),
    ];
    final tudo = engajamentoAtividade(eventos, filtro: EngajamentoFiltro.tudo);
    expect(tudo.map((e) => e.descricao), ['2 mensagens', 'A']);
    expect(
      engajamentoAtividade(
        eventos,
        filtro: EngajamentoFiltro.treinos,
        mostrarCancelados: true,
      ),
      hasLength(2),
    );
  });

  test('rota de próxima ação', () {
    expect(engajamentoEventoRota('MENSAGEM', 9), '/alunos/9/chat');
    expect(engajamentoEventoRota('MEDIDA', 9), '/alunos/9/evolucao');
    expect(engajamentoEventoRota('TREINO', 9), '/alunos/9/rotina');
    expect(engajamentoEventoRota('OUTRO', 9), isNull);
  });
}
