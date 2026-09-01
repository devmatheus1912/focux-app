import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/desafios/utils/desafio_display.dart';

void main() {
  test('desafioHubSubtitle junta freshness', () {
    expect(desafioHubSubtitle(null), 'Ranking e metas da comunidade');
    expect(
      desafioHubSubtitle('há 1 min'),
      'Ranking e metas da comunidade · há 1 min',
    );
  });

  test('desafioSubtitle formata tipo e meta', () {
    expect(
      desafioSubtitle(tipo: 'HABITOS', metaPontos: 100),
      'HABITOS · meta 100 pts',
    );
    expect(desafioSubtitle(tipo: '  ', metaPontos: 50), 'HABITOS · meta 50 pts');
  });

  test('desafioLeaderboard não expõe id', () {
    expect(desafioLeaderboardEmpty(), 'Nenhum participante com pontos ainda.');
    expect(desafioLeaderboardName('Ana'), 'Ana');
    expect(desafioLeaderboardName('  '), 'Aluno');
    expect(desafioLeaderboardName(null), 'Aluno');
    expect(desafioLeaderboardPoints(12), '12 pts');
    expect(desafioLeaderboardPoints(null), '0 pts');
  });
}
