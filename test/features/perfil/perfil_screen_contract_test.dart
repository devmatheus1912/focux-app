import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/theme_provider.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/providers/perfil_provider.dart';
import 'package:focux_app/features/perfil/screens/perfil_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';

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
          onboardingStatusProvider.overrideWith(
            (ref) async => OnboardingStatusData(
              perfilCompleto: false,
              primeiroAlunoAdicionado: true,
              primeiroTreinoCriado: true,
              pagamentoConfigurado: false,
              pacoteCriado: false,
              habitoConfigurado: false,
              linkBioConfigurado: false,
              treinoEnviado: true,
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: PerfilScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('QA Coach'), findsWidgets);
    expect(find.textContaining('Marca'), findsWidgets);
    expect(find.text('Prontidão comercial'), findsNothing);
    expect(find.text('Sua página'), findsOneWidget);
    expect(find.text('Vitrine'), findsNothing);
    expect(find.text('Seu código'), findsOneWidget);
    // O que falta vira cartão abaixo da identidade (fixture sem foto/telefone).
    expect(find.textContaining('% completo'), findsOneWidget);
    expect(find.textContaining('passos no seu perfil'), findsOneWidget);
    expect(find.text('Completar'), findsNothing);
    expect(find.text('Ver ao vivo'), findsNothing);
    expect(find.text('Migração Focux'), findsNothing);
    expect(find.text('Acesso dos alunos'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Aparência'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Aparência'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);
    expect(find.text('Negócio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Carteira e PIX'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Carteira e PIX'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Conta e segurança'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Meus alunos'), findsNothing);
    expect(find.text('Copiloto IA'), findsNothing);
    expect(find.text('Conta e segurança'), findsOneWidget);
    expect(find.text('Ferramentas de desenvolvimento'), findsNothing);
  });

  testWidgets('perfil completo esconde Completar (sem teaser de IA)', (
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
        ],
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: PerfilScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Acesso dos alunos'), findsOneWidget);
    expect(find.text('Cadastro completo'), findsNothing);
    expect(find.text('Completar'), findsNothing);
    expect(find.text('Perfil completo'), findsOneWidget);
    expect(find.textContaining('passos no seu perfil'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Negócio'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hoje'), findsNothing);
    expect(find.text('Meus alunos'), findsNothing);
    expect(find.text('Copiloto IA'), findsNothing);
    expect(find.text('Seu código'), findsOneWidget);
    expect(find.text('Ferramentas de desenvolvimento'), findsNothing);
    expect(find.byType(FxLiquidPrimaryButton), findsNothing);
  });

  testWidgets('conta: sem exclusão duplicada, Sair neutro e Excluir sozinho', (
    tester,
  ) async {
    DashboardHomeClientCache.clear();
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(DashboardHomeClientCache.clear);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _perfilCompletoFixture),
        ],
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: PerfilScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Ajuda e suporte'), findsOneWidget);
    expect(find.text('Como excluir sua conta'), findsNothing);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(find.text('Excluir minha conta'), findsOneWidget);
    expect(find.text('Preferências'), findsOneWidget);
    expect(find.text('Tema'), findsNothing);
    expect(find.text('Termos e privacidade'), findsOneWidget);
  });

  testWidgets('aparência troca o tema direto, sem abrir sheet', (tester) async {
    DashboardHomeClientCache.clear();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(DashboardHomeClientCache.clear);

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilProvider.overrideWith((ref) async => _perfilCompletoFixture),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: PerfilScreen());
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('Escuro'));
    await tester.pump();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(find.byType(BottomSheet), findsNothing);
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

