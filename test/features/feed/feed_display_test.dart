import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feed/data/feed_repository.dart';
import 'package:focux_app/features/feed/utils/feed_display.dart';

FeedPost _post(int id, {bool fixado = false}) =>
    FeedPost(id: id, titulo: '', conteudo: 'x', criadoEm: '', fixado: fixado);

void main() {
  test('chips de lista falam como o aluno', () {
    expect(FeedListChip.values.map(feedListChipLabel), [
      'Todas',
      'Fixados',
      'Fotos',
      'Vídeos',
      'Dicas',
    ]);
    expect(feedListChipTipo(FeedListChip.imagem), 'IMAGEM');
    expect(feedListChipTipo(FeedListChip.todos), isNull);
    expect(feedListChipFixado(FeedListChip.fixados), isTrue);
    expect(feedListChipFixado(FeedListChip.dica), isNull);
  });

  group('primeira linha vira título', () {
    test('duas linhas: a primeira é o título', () {
      final r = feedSepararTitulo(
        'Treino de sábado\nÀs 9h no parque. Levem água.',
      );
      expect(r.titulo, 'Treino de sábado');
      expect(r.conteudo, 'Às 9h no parque. Levem água.');
    });

    test('uma linha só fica como texto', () {
      final r = feedSepararTitulo('  Bom dia, turma!  ');
      expect(r.titulo, isEmpty);
      expect(r.conteudo, 'Bom dia, turma!');
    });

    test('primeira linha longa demais não vira título', () {
      final longa = 'a' * 81;
      final r = feedSepararTitulo('$longa\nresto');
      expect(r.titulo, isEmpty);
      expect(r.conteudo, '$longa\nresto');
    });

    test('editar junta título e texto de volta na caixa', () {
      expect(
        feedJuntarTitulo('Aviso', 'Sem aula sexta.'),
        'Aviso\nSem aula sexta.',
      );
      expect(feedJuntarTitulo('', 'Só texto'), 'Só texto');
    });
  });

  test('tempo por extenso', () {
    final agora = DateTime(2026, 11, 11, 12);
    expect(feedQuando(agora, agora: agora), 'agora');
    expect(
      feedQuando(agora.subtract(const Duration(minutes: 5)), agora: agora),
      'há 5 min',
    );
    expect(
      feedQuando(agora.subtract(const Duration(hours: 3)), agora: agora),
      'há 3 h',
    );
    expect(
      feedQuando(agora.subtract(const Duration(days: 1)), agora: agora),
      'ontem',
    );
    expect(
      feedQuando(agora.subtract(const Duration(days: 4)), agora: agora),
      'há 4 dias',
    );
    expect(
      feedQuando(agora.subtract(const Duration(days: 8)), agora: agora),
      'há 1 semana',
    );
    expect(
      feedQuando(agora.subtract(const Duration(days: 15)), agora: agora),
      'há 2 semanas',
    );
    expect(feedQuando(DateTime(2026, 9, 3), agora: agora), '03/09');
  });

  test('foto entre 4:5 e 1,91:1; fora disso, fundo desfocado', () {
    expect(feedProporcaoCartao(0.5), closeTo(0.8, 0.001));
    expect(feedProporcaoCartao(1.5), 1.5);
    expect(feedProporcaoCartao(3), closeTo(1.91, 0.001));
    expect(feedPrecisaFundo(0.5), isTrue);
    expect(feedPrecisaFundo(1.0), isFalse);
    expect(feedPrecisaFundo(2.5), isTrue);
  });

  test('bloco Fixado só sem filtro', () {
    final posts = [_post(1), _post(2, fixado: true), _post(3)];
    final sem = feedSepararFixados(posts, filtrando: false);
    expect(sem.fixados.map((p) => p.id), [2]);
    expect(sem.outros.map((p) => p.id), [1, 3]);
    final com = feedSepararFixados(posts, filtrando: true);
    expect(com.fixados, isEmpty);
    expect(com.outros.map((p) => p.id), [1, 2, 3]);
  });

  test('post do aviso vem primeiro', () {
    final posts = [_post(1), _post(2), _post(3)];
    expect(feedComDestaque(posts, 3).map((p) => p.id), [3, 1, 2]);
    expect(feedComDestaque(posts, 99).map((p) => p.id), [1, 2, 3]);
    expect(feedComDestaque(posts, null).map((p) => p.id), [1, 2, 3]);
  });

  test('contador de curtidas', () {
    expect(feedCurtidasLabel(1), '1 curtida');
    expect(feedCurtidasLabel(3), '3 curtidas');
  });
}
