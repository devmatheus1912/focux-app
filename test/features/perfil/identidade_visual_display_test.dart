import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/identidade_visual_display.dart';

void main() {
  test('gate de marca branca usa a feature e cai no plano', () {
    expect(
      identidadeHasWhiteLabel(featureWhiteLabel: true, plano: 'PRO'),
      isTrue,
    );
    expect(
      identidadeHasWhiteLabel(featureWhiteLabel: false, plano: 'ENTERPRISE'),
      isFalse,
    );
    expect(
      identidadeHasWhiteLabel(
        featureWhiteLabel: null,
        plano: 'enterprise_pro',
      ),
      isTrue,
    );
    expect(
      identidadeHasWhiteLabel(featureWhiteLabel: null, plano: 'PRO'),
      isFalse,
    );
  });

  test('copy da identidade confirma save, restore e logo', () {
    expect(identidadeSalvarLabel(isSetup: true), 'Finalizar configuração');
    expect(identidadeSalvarLabel(isSetup: false), 'Salvar marca');
    expect(identidadeSalvarConfirmMessage(), contains('login dos alunos'));
    expect(identidadeRestaurarConfirmTitle(), contains('cores padrão'));
    expect(identidadeLogoConfirmMessage(), contains('rascunho'));
    expect(identidadeLandingEditorLabel(), 'Editor da landing');
  });
}
