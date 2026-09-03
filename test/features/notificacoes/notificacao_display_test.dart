import 'package:flutter_test/flutter_test.dart';
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
    expect(notificacaoCountLabel(0), 'Nenhuma');
    expect(notificacaoCountLabel(1), '1 aviso');
    expect(notificacaoCountLabel(4), '4 avisos');
    expect(notificacaoComoCalculamos, contains('Radar'));
    expect(notificacaoSearchEmptyTitle(''), 'Tudo em ordem');
    expect(notificacaoSearchEmptyTitle('treino'), 'Nenhum aviso encontrado');
    expect(notificacaoSearchEmptySubtitle('treino'), contains('texto'));
  });
}
