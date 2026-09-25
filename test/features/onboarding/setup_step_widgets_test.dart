import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_command_center_sticky_header.dart';
import 'package:focux_app/core/widgets/fx_action_chip.dart';
import 'package:focux_app/features/onboarding/utils/setup_action_navigation.dart';
import 'package:focux_app/features/onboarding/widgets/setup_step_widgets.dart';

void main() {
  group('normalizeSetupActionRoute', () {
    test('mapeia rotas legadas do backend', () {
      expect(normalizeSetupActionRoute('/treinos'), '/treinos/novo');
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

  testWidgets('CTA compacto da Home não estica na tela', (tester) async {
    const screen = Size(400, 800);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: screen.width,
            height: screen.height,
            child: Stack(
              children: [
                DashboardPrioritiesOverlay(
                  isDark: false,
                  primary: const Color(0xFF0B4F5C),
                  label: 'Continuar',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final chip = tester.getSize(find.text('Continuar'));
    expect(chip.width, lessThan(screen.width / 2));
    expect(chip.height, lessThan(80));

    final labelBox = tester.getRect(find.text('Continuar'));
    final materialBox = tester.getRect(
      find.descendant(
        of: find.byType(FxActionChip),
        matching: find.byType(Material),
      ),
    );
    expect((labelBox.center.dy - materialBox.center.dy).abs(), lessThan(1.5));
    expect((labelBox.center.dx - materialBox.center.dx).abs(), lessThan(1.5));
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
