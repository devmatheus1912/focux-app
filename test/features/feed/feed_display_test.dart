import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feed/utils/feed_display.dart';

void main() {
  test('chips de lista mapeiam tipo e fixado', () {
    expect(feedListChipLabel(FeedListChip.fixados), 'Fixados');
    expect(feedListChipTipo(FeedListChip.imagem), 'IMAGEM');
    expect(feedListChipTipo(FeedListChip.todos), isNull);
    expect(feedListChipFixado(FeedListChip.fixados), isTrue);
    expect(feedListChipFixado(FeedListChip.dica), isNull);
  });

  test('publicar limita tamanho', () {
    expect(feedTituloMax, 255);
    expect(feedConteudoMax, 4000);
    expect(feedPublicarTileLabel(), 'Publicar');
  });
}
