import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:focux_app/features/notificacoes/notificacao_display.dart';
import 'package:focux_app/features/notificacoes/widgets/notificacao_badge_button.dart';

void main() {
  test('formatDisplayName title-cases single and multi-word names', () {
    expect(formatDisplayName('thales'), 'Thales');
    expect(formatDisplayName('  nathalia costa  '), 'Nathalia Costa');
    expect(formatDisplayName('maria da silva'), 'Maria da Silva');
  });

  test('radarSignalDedupeKey ignora casing e espacos duplicados', () {
    final a = radarSignalDedupeKey(
      displayName: 'Thales',
      summary: 'Retomar treino com mensagem curta',
      route: '/alunos/1',
    );
    final b = radarSignalDedupeKey(
      displayName: 'thales',
      summary: '  Retomar   treino com mensagem curta ',
      route: '/alunos/1',
    );
    expect(a, b);
  });

  test('tooltip da badge descreve a contagem', () {
    expect(notificacaoBadgeTooltip(0), 'Notificações');
    expect(notificacaoBadgeTooltip(1), '1 notificação');
    expect(notificacaoBadgeTooltip(3), '3 notificações');
    expect(notificacaoBadgeTooltip(9), '9 notificações');
    expect(notificacaoBadgeTooltip(12), '9 ou mais notificações');
    expect(notificacaoNaoLidasLabel(0), 'Tudo lido');
    expect(notificacaoNaoLidasLabel(1), '1 não lida');
    expect(notificacaoNaoLidasLabel(4), '4 não lidas');
    expect(notificacaoComoCalculamos, contains('inbox de chat'));
    expect(notificacaoComoCalculamos, isNot(contains('chat e Radar')));
    expect(notificacaoComoCalculamos, contains('Radar'));
    expect(notificacaoSearchEmptyTitle(''), 'Tudo em ordem');
    expect(notificacaoSearchEmptyTitle('treino'), 'Nenhum aviso encontrado');
    expect(notificacaoSearchEmptySubtitle('treino'), contains('texto'));
  });

  test('rótulos de limpeza e filtro', () {
    expect(notificacaoRemovidasLabel(0), 'Nada para limpar.');
    expect(notificacaoRemovidasLabel(1), '1 notificação apagada.');
    expect(notificacaoRemovidasLabel(5), '5 notificações apagadas.');
    expect(notificacaoFiltroNaoLidasLabel(0), 'Não lidas');
    expect(notificacaoFiltroNaoLidasLabel(3), 'Não lidas · 3');
    expect(notificacaoVazioTitle(query: '', soNaoLidas: true), 'Nada pendente');
    expect(notificacaoVazioTitle(query: '', soNaoLidas: false), 'Tudo em ordem');
    expect(
      notificacaoVazioTitle(query: 'pix', soNaoLidas: true),
      'Nenhum aviso encontrado',
    );
  });

  test('notificacoesVisiveis esconde apagadas e filtra não lidas', () {
    const lida = NotificacaoApp(
      id: 1,
      titulo: 'A',
      mensagem: '',
      tipo: 'INFO',
      lida: true,
    );
    const nova = NotificacaoApp(
      id: 2,
      titulo: 'B',
      mensagem: '',
      tipo: 'INFO',
      lida: false,
    );
    const outra = NotificacaoApp(
      id: 3,
      titulo: 'C',
      mensagem: '',
      tipo: 'INFO',
      lida: false,
    );
    final todas = [lida, nova, outra];

    expect(notificacoesVisiveis(todas).map((n) => n.id), [1, 2, 3]);
    expect(
      notificacoesVisiveis(todas, ocultas: {2}).map((n) => n.id),
      [1, 3],
    );
    expect(
      notificacoesVisiveis(todas, soNaoLidas: true).map((n) => n.id),
      [2, 3],
    );
  });
}
