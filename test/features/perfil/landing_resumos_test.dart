import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_screen.dart';

void main() {
  test('resumo com os títulos dos itens', () {
    expect(
      landingResumoTitulos(['Diagnóstico', ' Programa ', '', 'Ajustes'], vazio: 'Ainda vazio'),
      'Diagnóstico, Programa, Ajustes',
    );
    expect(landingResumoTitulos(const [], vazio: 'Ainda vazio'), 'Ainda vazio');
  });

  test('depoimentos aprovados', () {
    expect(landingDepoimentosResumo(0), 'Nenhum aprovado ainda');
    expect(landingDepoimentosResumo(1), '1 aprovado');
    expect(landingDepoimentosResumo(4), '4 aprovados');
  });
}
