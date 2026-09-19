import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/relatorio/utils/relatorio_global_display.dart';

void main() {
  test('relatorioAderenciaMediaLabel formata a média da base', () {
    expect(relatorioAderenciaMediaLabel(72.3), '72.3%');
    expect(relatorioAderenciaMediaLabel(0), '0.0%');
    expect(relatorioAderenciaMediaLabel(140), '100.0%');
  });

  test('relatorioAderenciaPercentLabel ignora divisão por zero', () {
    expect(relatorioAderenciaPercentLabel(0, 0), '0%');
    expect(relatorioAderenciaPercentLabel(3, 4), '75%');
  });

  test('relatorioTreinosSubtitle pluraliza', () {
    expect(relatorioTreinosSubtitle(0, 0), 'Ainda sem dias com check-in');
    expect(relatorioTreinosSubtitle(1, 1), '1 de 1 dia com check-in');
    expect(relatorioTreinosSubtitle(3, 8), '3 de 8 dias com check-in');
  });

  test('relatorioUltimoTreinoLabel formata data BR e vazio', () {
    expect(relatorioUltimoTreinoLabel(null), 'Sem treinos');
    expect(relatorioUltimoTreinoLabel(''), 'Sem treinos');
    expect(relatorioUltimoTreinoLabel('2026-08-31'), '31 de agosto de 2026');
    expect(relatorioRankingPreview([1, 2, 3, 4]), [1, 2, 3]);
    expect(relatorioAderenciaPct(3, 4), 75);
    expect(relatorioAderenciaPct(1, 0), 0);
    expect(
      relatorioRankingSearch(['Ana', 'Bia', 'Cris'], 'bi', (nome) => nome),
      ['Bia'],
    );
    expect(
      relatorioRankingSearch(['Ana', 'Bia'], '  ', (nome) => nome),
      ['Ana', 'Bia'],
    );
    expect(firstRelatorioAtencao(['Ana', 'Bia']), 'Ana');
    expect(firstRelatorioAtencao(<String>[]), isNull);
    expect(relatorioComoCalculamos, contains('Média'));
  });
}
