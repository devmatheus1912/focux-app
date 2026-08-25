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

  testWidgets('CTA do wizard não estica na tela', (tester) async {
    const screen = Size(400, 800);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: screen.width,
            height: screen.height,
            child: Stack(
              children: [
                SetupWizardCta(
                  label: 'Continuar setup',
                  accent: const Color(0xFF13C2C2),
                  isDark: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final chip = tester.getSize(find.text('Continuar setup'));
    expect(chip.width, lessThan(screen.width / 2));
    expect(chip.height, lessThan(80));
  });

  testWidgets('passo pendente tem Semantics de botão', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetupStepCard(
            title: 'Complete seu perfil',
            description: 'Cor da marca e bio profissional.',
            estimatedMinutes: 2,
            icon: 'person',
            completed: false,
            isLead: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('Complete seu perfil')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('pendente')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Cor da marca e bio profissional')),
      findsOneWidget,
    );
  });

  testWidgets('hero e linhas no dark sem overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: Column(
            children: [
              SetupProgressHeroCard(
                progressPercent: 14,
                completedCount: 1,
                totalCount: 7,
              ),
              SetupStepCard(
                title: 'Complete seu perfil',
                description: 'Cor da marca e bio profissional.',
                estimatedMinutes: 2,
                icon: 'person',
                completed: false,
                isLead: true,
              ),
              SetupStepCard(
                title: 'Crie seu link na bio',
                icon: 'link',
                completed: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(tester.takeException(), isNull);
    expect(find.text('Sua ativação'), findsOneWidget);
    expect(find.text('14% concluído'), findsOneWidget);
    expect(find.text('Complete seu perfil'), findsOneWidget);
  });

  testWidgets('fold inset não transborda em landscape', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 360,
            child: Stack(
              children: [
                ListView(
                  children: const [
                    SetupProgressHeroCard(
                      progressPercent: 14,
                      completedCount: 1,
                      totalCount: 7,
                    ),
                    SetupStepCard(
                      title: 'Cadastre seu primeiro aluno',
                      description: 'Cadastre ou importe da concorrência.',
                      estimatedMinutes: 2,
                      icon: 'person_add',
                      completed: false,
                      isLead: true,
                    ),
                  ],
                ),
                SetupWizardCta(
                  label: 'Continuar setup',
                  accent: const Color(0xFF13C2C2),
                  isDark: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(tester.takeException(), isNull);
    expect(find.text('Cadastre seu primeiro aluno'), findsOneWidget);
    expect(find.text('Continuar setup'), findsOneWidget);
  });
}
