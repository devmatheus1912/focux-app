import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/utils/engajamento_display.dart';

void main() {
  final hoje = DateTime(2026, 11, 10);

  test('ficha trocada há 3 dias num aluno antigo avisa', () {
    expect(
      engajamentoFichaNova(DateTime(2026, 11, 7), hoje: hoje, diaDaFicha: 60),
      'Ficha nova há 3 dias: a aderência começa a refletir ela.',
    );
  });

  test('primeira ficha (Começando) e ficha antiga não avisam', () {
    expect(engajamentoFichaNova(DateTime(2026, 11, 7), hoje: hoje, diaDaFicha: 4), isNull);
    expect(engajamentoFichaNova(DateTime(2026, 10, 1), hoje: hoje, diaDaFicha: 60), isNull);
    expect(engajamentoFichaNova(null, hoje: hoje, diaDaFicha: 60), isNull);
  });
}
