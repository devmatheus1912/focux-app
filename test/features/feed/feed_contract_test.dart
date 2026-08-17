import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feed/data/feed_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('feed models parse author and comment avatars', () {
    final post = FeedPost.fromJson({
      'id': 7,
      'titulo': 'Treino',
      'conteudo': 'Tomem agua hoje.',
      'tipoPost': 'DICA',
      'autorNome': 'QA Coach',
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

    expect(post.autorNome, 'QA Coach');
    expect(post.autorAvatarUrl, 'https://cdn.focux.test/personal.jpg');
    expect(comentario.alunoFotoUrl, 'https://cdn.focux.test/thales.jpg');

    final comentarioComAlias = FeedComentario.fromJson({
      'id': 12,
      'alunoId': 2,
      'alunoNome': 'thales',
      'avatarUrl': 'https://cdn.focux.test/avatar-alias.jpg',
      'texto': 'Alias.',
      'criadoEm': '2026-05-05T15:02:00',
    });
    expect(
      comentarioComAlias.alunoFotoUrl,
      'https://cdn.focux.test/avatar-alias.jpg',
    );
  });

  test('feed composer uploads media instead of asking for URL', () {
    final screen = readScreenSourceBundle(
      'lib/features/feed/screens/feed_screen.dart',
    );

    expect(screen, contains('ImagePicker'));
    expect(screen, contains('MediaUploadService'));
    expect(screen, contains('feed/images'));
    expect(screen, contains('feed/videos'));
    expect(screen, isNot(contains('URL da mídia')));
  });
}
