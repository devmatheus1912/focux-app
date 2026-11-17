import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_video_rede.dart';

/// Vídeo do personal gravado em pé não encolhe numa caixa 16:9 nem passa da
/// tela (iPhone: 358 de largura útil, 844 de altura).
void main() {
  test('deitado 16:9 ocupa a largura toda', () {
    final c = fxVideoCaixa(largura: 358, alturaTela: 844, aspectRatio: 16 / 9);
    expect(c.width, 358);
    expect(c.height, closeTo(201.4, 0.1));
  });

  test('em pé 9:16 cresce até metade da tela, sem cortar nem passar', () {
    final c = fxVideoCaixa(largura: 358, alturaTela: 844, aspectRatio: 9 / 16);
    expect(c.height, 422);
    expect(c.width, closeTo(237.4, 0.1));
  });

  test('respeita a altura do pai', () {
    final c = fxVideoCaixa(
      largura: 358,
      alturaTela: 844,
      aspectRatio: 9 / 16,
      alturaMax: 300,
    );
    expect(c.height, 300);
    expect(c.width, closeTo(168.75, 0.01));
  });

  test('sem proporção conhecida, 16:9', () {
    final c = fxVideoCaixa(largura: 320, alturaTela: 800, aspectRatio: 0);
    expect(c.height, 180);
  });
}
