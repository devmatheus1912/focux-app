import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feed/data/feed_repository.dart';

void main() {
  test('feed models parse author and comment avatars', () {
    final post = FeedPost.fromJson({
      'id': 7,
      'titulo': 'Treino',
      'conteudo': 'Tomem agua hoje.',
      'tipoPost': 'DICA',
      'autorNome': 'Matheus Focux',
      'autorAvatarUrl': 'https://cdn.focux.test/personal.jpg',
      'totalCurtidas': 1,
      'totalComentarios': 1,
      'criadoEm': '2026-05-05T15:00:00',
    });
    final comentario = FeedComentario.fromJson({
      'id': 11,
      'alunoId': 2,
      'alunoNome': 'thales',
      'alunoFotoUrl': 'https://cdn.focux.test/thales.jpg',
      'conteudo': 'Sempre mestre.',
      'criadoEm': '2026-05-05T15:01:00',
    });

    expect(post.autorNome, 'Matheus Focux');
    expect(post.autorAvatarUrl, 'https://cdn.focux.test/personal.jpg');
    expect(comentario.alunoFotoUrl, 'https://cdn.focux.test/thales.jpg');
  });
}
