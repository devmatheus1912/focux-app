import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/providers/perfil_provider.dart';
import 'package:focux_app/features/perfil/screens/perfil_screen.dart';

void main() {
  testWidgets('perfil personal renders compact hub for the coach', (
    tester,
  ) async {
    DashboardHomeClientCache.clear();
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(DashboardHomeClientCache.clear);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _perfilFixture),
          dashboardProvider.overrideWith((ref) async => _dashboardFixture),
        ],
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('QA Coach'), findsWidgets);
    expect(find.textContaining('Marca'), findsWidgets);
    expect(find.text('Prontidão comercial'), findsOneWidget);
    expect(find.text('Marca e vitrine'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
    expect(find.text('Completar cadastro'), findsOneWidget);
    expect(find.text('WhatsApp pendente'), findsOneWidget);
    expect(find.textContaining('alunos'), findsWidgets);

    expect(find.text('Operação'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Operação'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Operação'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Carteira e PIX'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Conta e segurança'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Completar'), findsOneWidget);
    expect(find.text('Meus alunos'), findsNothing);
    expect(find.text('Copiloto IA'), findsNothing);
    expect(find.text('Conta e segurança'), findsOneWidget);
    expect(find.text('Ferramentas de desenvolvimento'), findsNothing);
  });

  testWidgets('perfil completo usa sticky Hoje (sem teaser de IA)', (
    tester,
  ) async {
    DashboardHomeClientCache.clear();
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(DashboardHomeClientCache.clear);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _perfilCompletoFixture),
          dashboardProvider.overrideWith((ref) async => _dashboardFixture),
        ],
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('alunos'), findsWidgets);
    expect(find.text('Cadastro completo'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Operação'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Meus alunos'), findsNothing);
    expect(find.text('Copiloto IA'), findsNothing);
    expect(find.text('Compartilhar'), findsOneWidget);
    expect(find.text('Ferramentas de desenvolvimento'), findsNothing);
    expect(find.byType(FxLiquidPrimaryButton), findsNothing);
  });
}

final _perfilCompletoFixture = PerfilPersonal(
  id: 7,
  nome: 'QA Coach',
  email: 'qa@example.com',
  telefone: '62982213003',
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
  logoUrl: 'https://cdn.example.com/qa-coach.png',
);

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
