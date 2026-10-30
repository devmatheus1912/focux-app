import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/utils/setup_action_navigation.dart';
import 'package:focux_app/features/onboarding/widgets/setup_step_widgets.dart';

void main() {
  group('normalizeSetupActionRoute', () {
    test('mapeia rotas legadas do backend', () {
      expect(normalizeSetupActionRoute('/treinos'), '/treinos?novo=1');
      expect(normalizeSetupActionRoute('/treinos/novo'), '/treinos?novo=1');
      expect(normalizeSetupActionRoute('/financeiro'), '/perfil/wallet');
      expect(normalizeSetupActionRoute('/perfil'), '/perfil/editar');
      expect(normalizeSetupActionRoute('/pacotes'), '/pacotes');
    });

    test('passo perfil do setup aponta para edição com dados', () {
      expect(isSetupPerfilEditRoute('/perfil'), isTrue);
      expect(isSetupPerfilEditRoute('/perfil/editar'), isTrue);
      expect(isSetupPerfilEditRoute('/perfil/wallet'), isFalse);
    });
  });

  group('setupStepFxIconName', () {
    test('mapeia icones do backend para FxIcon', () {
      expect(setupStepFxIconName('fitness_center'), 'dumbbell');
      expect(setupStepFxIconName('attach_money'), 'pix');
    });
  });

  testWidgets('skeleton do setup não transborda', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SetupWizardSkeleton()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SetupWizardSkeleton), findsOneWidget);
  });
}
