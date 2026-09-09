import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_fotos_display.dart';

void main() {
  test('evolucaoFotosCountLabel', () {
    expect(evolucaoFotosCountLabel(0), 'Nenhuma foto');
    expect(evolucaoFotosCountLabel(1), '1 foto');
    expect(evolucaoFotosCountLabel(4), '4 fotos');
  });

  test('evolucaoFotosDateLabel', () {
    expect(evolucaoFotosDateLabel('texto'), 'texto');
    expect(evolucaoFotosDateLabel('2026-09-02T15:00:00'), '02/09');
  });
}
