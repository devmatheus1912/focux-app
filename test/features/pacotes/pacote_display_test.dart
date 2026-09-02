import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/pacotes/utils/pacote_display.dart';

void main() {
  test('pacoteDuracaoLabel', () {
    expect(pacoteDuracaoLabel(1), '1 mês');
    expect(pacoteDuracaoLabel(0), '1 mês');
    expect(pacoteDuracaoLabel(12), '12 meses');
    expect(pacoteDuracaoMesesValues, [1, 3, 6, 12]);
  });

  test('pacoteIncluiValue', () {
    expect(pacoteIncluiValue(true), 'Sim');
    expect(pacoteIncluiValue(false), 'Não');
  });

  test('criar e desativar confirmam', () {
    expect(pacoteTituloMax, 120);
    expect(pacoteDescricaoMax, 4000);
    expect(pacoteCriarTileLabel(), 'Criar plano');
    expect(pacoteCriarConfirmTitle(), 'Publicar este plano?');
    expect(
      pacoteCriarConfirmMessage(),
      'Quem abrir seu link passa a ver este plano na página de vendas.',
    );
    expect(pacoteCriarConfirmLabel(), 'Publicar');
    expect(pacoteDesativarConfirmTitle(), 'Desativar plano?');
    expect(
      pacoteDesativarConfirmMessage('Musculação'),
      '“Musculação” some da sua página na internet. Você pode criar outro depois.',
    );
    expect(pacoteDesativarConfirmLabel(), 'Desativar');
  });
}
