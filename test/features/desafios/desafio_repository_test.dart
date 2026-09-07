import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/desafios/data/desafio_repository.dart';

void main() {
  test('Desafio parseia prazo e meta do contrato', () {
    final desafio = Desafio.fromJson({
      'id': 3,
      'titulo': '30 dias de água',
      'descricao': 'Beber 2L',
      'tipo': 'HABITOS',
      'metaPontos': 80,
      'inicio': '2026-09-07',
      'fim': '2026-10-07',
    });
    expect(desafio.id, 3);
    expect(desafio.titulo, '30 dias de água');
    expect(desafio.descricao, 'Beber 2L');
    expect(desafio.tipo, 'HABITOS');
    expect(desafio.metaPontos, 80);
    expect(desafio.inicio, DateTime(2026, 9, 7));
    expect(desafio.fim, DateTime(2026, 10, 7));
  });

  test('leaderboard parseia aluno sem Map cru', () {
    final entry = DesafioLeaderboardEntry.fromJson({
      'alunoId': 9,
      'alunoNome': 'Ana',
      'pontos': 40,
    });
    expect(entry.alunoId, 9);
    expect(entry.alunoNome, 'Ana');
    expect(entry.pontos, 40);
  });
}
