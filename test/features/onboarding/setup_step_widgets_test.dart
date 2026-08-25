import 'package:flutter/material.dart';
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

  testWidgets('passo pendente destaca o título sem pílula AGORA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetupStepCard(
            title: 'Complete seu perfil',
            description: 'Adicione cor da marca',
            estimatedMinutes: 2,
            icon: 'person',
            completed: false,
            isLead: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('AGORA'), findsNothing);
    expect(find.text('Complete seu perfil'), findsOneWidget);
    expect(find.text('Adicione cor da marca'), findsOneWidget);
    expect(find.text('~2 min'), findsOneWidget);
  });
}
