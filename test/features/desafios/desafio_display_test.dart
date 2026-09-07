import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/desafios/utils/desafio_display.dart';

void main() {
  test('desafioHubSubtitle junta contagem e freshness', () {
    expect(desafioHubSubtitle(count: 0), 'Nenhum desafio');
    expect(
      desafioHubSubtitle(count: 2, freshness: 'há 1 min'),
      '2 desafios · há 1 min',
    );
    expect(desafioCountLabel(1), '1 desafio');
  });

  test('desafioSubtitle formata tipo, prazo e meta', () {
    expect(
      desafioSubtitle(tipo: 'HABITOS', metaPontos: 100),
      'Hábitos · meta 100 pts',
    );
    expect(
      desafioSubtitle(tipo: '  ', metaPontos: 50),
      'Hábitos · meta 50 pts',
    );
    expect(
      desafioSubtitle(
        tipo: 'TREINOS',
        metaPontos: 200,
        inicio: DateTime(2026, 9, 1),
        fim: DateTime(2026, 9, 30),
      ),
      '01/09 – 30/09 · Treinos · 200 pts',
    );
    expect(desafioTipoLabel('TREINOS'), 'Treinos');
    expect(desafioDuracaoLabel(30), '30 dias');
    expect(desafioMetaLabel(100), '100 pts');
  });

  test('filtro de tipo e leaderboard não expõem id', () {
    expect(desafioMatchesFiltro('HABITOS', DesafioTipoFiltro.todos), isTrue);
    expect(desafioMatchesFiltro('HABITOS', DesafioTipoFiltro.habitos), isTrue);
    expect(desafioMatchesFiltro('HABITOS', DesafioTipoFiltro.treinos), isFalse);
    expect(desafioFiltroLabel(DesafioTipoFiltro.treinos), 'Treinos');
    expect(desafioLeaderboardEmpty(), 'Nenhum participante com pontos ainda.');
    expect(desafioLeaderboardName('Ana'), 'Ana');
    expect(desafioLeaderboardName('  '), 'Aluno');
    expect(desafioLeaderboardName(null), 'Aluno');
    expect(desafioLeaderboardPoints(12), '12 pts');
    expect(desafioLeaderboardPoints(null), '0 pts');
  });
}
