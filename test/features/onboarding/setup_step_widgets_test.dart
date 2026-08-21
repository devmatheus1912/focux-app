import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/widgets/setup_step_widgets.dart';

void main() {
  group('normalizeSetupActionRoute', () {
    test('mapeia rotas legadas do backend', () {
      expect(normalizeSetupActionRoute('/treinos'), '/treinos/novo');
      expect(normalizeSetupActionRoute('/financeiro'), '/perfil/wallet');
      expect(normalizeSetupActionRoute('/perfil'), '/perfil/editar');
      expect(normalizeSetupActionRoute('/pacotes'), '/pacotes');
    });
  });

  group('setupStepFxIconName', () {
    test('mapeia icones do backend para FxIcon', () {
      expect(setupStepFxIconName('fitness_center'), 'dumbbell');
      expect(setupStepFxIconName('attach_money'), 'pix');
    });
  });
}
