import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await tester.scrollUntilVisible(
      find.text('Carteira e PIX'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Operação'), findsOneWidget);
    expect(find.text('Meus alunos'), findsOneWidget);
    // Fixture incompleto (WhatsApp pendente) → sticky pede completar, não Copiloto/Hoje.
    expect(find.text('Completar perfil'), findsOneWidget);
    expect(find.text('Copiloto IA'), findsNothing);
    // Conta quiet + debug fora do card LGPD.
    expect(find.text('Conta e segurança'), findsOneWidget);
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

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Copiloto IA'), findsNothing);
    expect(find.text('Meus alunos'), findsOneWidget);
    expect(find.text('Cadastro completo'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
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
  logoUrl: 'https://cdn.example.com/logo.png',
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
