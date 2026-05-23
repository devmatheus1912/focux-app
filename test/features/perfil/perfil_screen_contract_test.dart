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
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Matheus Focux'), findsWidgets);
    expect(find.text('Prontidao comercial'), findsOneWidget);
    expect(find.text('Identidade visual'), findsOneWidget);
    expect(find.text('Marca'), findsWidgets);
    expect(find.bySemanticsLabel('Restaurar cores padrão do Focux'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Carteira e PIX'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Carteira e PIX'), findsOneWidget);
    expect(find.text('Convidar alunos'), findsOneWidget);
    expect(find.text('Meus alunos'), findsOneWidget);
  });
}

final _perfilFixture = PerfilPersonal(
  id: 7,
  nome: 'Matheus Focux',
  email: 'matheus@personal.com',
  cref: '123456-G/SP',
  especialidade: 'Hipertrofia',
  corPrimaria: '#2D4FB7',
  corSecundaria: '#3F63E4',
  slug: 'matheus-focux',
  plano: 'ENTERPRISE',
  chavePix: 'matheus@personal.com',
  descricaoProfissional: 'Especializado em biomecanica.',
  especialidades: 'Hipertrofia',
  instagram: '@devmatheusb',
);

final _dashboardFixture = DashboardData(
  totalAlunos: 6,
  alunosAtivos: 5,
  planoAtual: 'ENTERPRISE',
  limiteAlunos: 120,
  nomePersonal: 'Matheus Focux',
  logoUrl: null,
  corPrimaria: '#2D4FB7',
  corSecundaria: '#3F63E4',
  descricaoProfissional: 'Especializado em biomecanica.',
  instagram: '@devmatheusb',
);
