import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/desafios/utils/desafio_display.dart';

void main() {


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


  test('desafio detalhe conta prazo, meta e caminhos', () {
    expect(desafioDetailPath(4), '/desafios/4');
    expect(desafioAlunoDetailPath(4), '/aluno/desafios/4');
    expect(
      desafioDiasRestantesValue(
        DateTime(2026, 9, 7),
        now: DateTime(2026, 9, 7),
      ),
      'Hoje',
    );
    expect(
      desafioDiasRestantesValue(
        DateTime(2026, 9, 10),
        now: DateTime(2026, 9, 7),
      ),
      '3',
    );
    expect(
      desafioDiasRestantesHint(
        DateTime(2026, 9, 6),
        now: DateTime(2026, 9, 7),
      ),
      'Fora do prazo',
    );
    expect(desafioParticipantesHint(0), 'Ninguém no ranking');
    expect(desafioParticipantesHint(2), '2 participantes');
    expect(desafioAtingiramMeta(const [40, 100, 120], 100), 2);
    expect(
      desafioMetaAtingidaValue(atingiram: 2, total: 5),
      '2/5',
    );
    expect(desafioStickyEncerrarLabel(), 'Encerrar desafio');
    expect(desafioStickyAlunoLabel('TREINOS'), 'Ir aos treinos');
    expect(desafioStickyAlunoPath('HABITOS'), '/aluno/habitos');
    expect(desafioLugarLabel(0), '1º lugar');
    expect(desafioMeuIndex(const [4, 9, 2], 9), 1);
    expect(desafioMeuIndex(const [4, 9], null), isNull);
    expect(desafioMeuLugarValue(0), '1º');
    expect(desafioMeuLugarValue(null), '—');
    expect(
      desafioMeuLugarHint(index: 0, pontos: 120, metaPontos: 100),
      'Meta atingida',
    );
    expect(
      desafioMeuLugarHint(index: 2, pontos: 40, metaPontos: 100),
      '40 de 100 pts',
    );
    expect(
      desafioLeaderboardTitle(nome: 'Ana', isSelf: true),
      'Você',
    );
    expect(desafioCampanhaEmpty(), contains('Sem descrição'));
  });
}
