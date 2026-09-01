import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feed/utils/feed_display.dart';

void main() {
  test('feedTipoLabel em PT-BR', () {
    expect(feedTipoLabel('TEXTO'), 'Texto');
    expect(feedTipoLabel('IMAGEM'), 'Imagem');
    expect(feedTipoLabel('VIDEO'), 'Vídeo');
    expect(feedTipoLabel('ENQUETE'), 'Enquete');
    expect(feedTipoLabel('DICA'), 'Dica rápida');
    expect(feedTipoLabel(null), 'Texto');
    expect(feedTipoLabel('  '), 'Texto');
    expect(feedTipoValues, containsAll(['TEXTO', 'IMAGEM', 'VIDEO', 'ENQUETE', 'DICA']));
  });

  test('feedHubSubtitle e mídia', () {
    expect(feedHubSubtitle(null), 'Novidades para os seus alunos');
    expect(
      feedHubSubtitle('há 1 min'),
      'Novidades para os seus alunos · há 1 min',
    );
    expect(feedTipoTemMidia('IMAGEM'), isTrue);
    expect(feedTipoTemMidia('VIDEO'), isTrue);
    expect(feedTipoTemMidia('TEXTO'), isFalse);
    expect(feedMidiaCta(tipo: 'VIDEO', hasFile: false), 'Escolher vídeo');
    expect(feedMidiaCta(tipo: 'IMAGEM', hasFile: true), 'Trocar arquivo');
  });
}
