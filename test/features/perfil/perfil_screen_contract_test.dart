import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/providers/perfil_provider.dart';
import 'package:focux_app/features/perfil/screens/perfil_screen.dart';

void main() {
  testWidgets('perfil personal renders premium controls and readiness', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _perfilFixture),
          dashboardProvider.overrideWith((ref) async => _dashboardFixture),
        ],
        child: MaterialApp(
          home: const PerfilScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('QA Coach'), findsWidgets);
    // Incompleto: prontidão sobe para o 1º bloco de conteúdo.
    expect(find.text('Prontidão comercial'), findsOneWidget);
    expect(find.text('Marca e vitrine'), findsOneWidget);
    expect(find.text('Marca'), findsWidgets);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Paleta ativa · toque para editar'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Carteira e PIX'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Operação'), findsOneWidget);
    expect(find.text('Conta e segurança'), findsOneWidget);
    expect(find.text('Carteira e PIX'), findsOneWidget);
    expect(find.text('Meus alunos'), findsOneWidget);
    expect(find.text('Copiloto IA'), findsOneWidget);
  });
}

final _perfilFixture = PerfilPersonal(
  id: 7,
  nome: 'QA Coach',
  email: 'qa@example.com',
  cref: '123456-G/SP',
  especialidade: 'Hipertrofia',
  corPrimaria: '#2D4FB7',
  corSecundaria: '#3F63E4',
  slug: 'qa-demo-coach',
  plano: 'ENTERPRISE',
  chavePix: 'qa@example.com',
  descricaoProfissional: 'Especializado em biomecanica.',
  especialidades: 'Hipertrofia',
  instagram: '@qacoach',
);

final _dashboardFixture = DashboardData(
  totalAlunos: 6,
  alunosAtivos: 5,
  planoAtual: 'ENTERPRISE',
  limiteAlunos: 120,
  nomePersonal: 'QA Coach',
  logoUrl: null,
  corPrimaria: '#2D4FB7',
  corSecundaria: '#3F63E4',
  descricaoProfissional: 'Especializado em biomecanica.',
  instagram: '@qacoach',
);
