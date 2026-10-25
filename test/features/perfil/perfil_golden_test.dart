@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/providers/perfil_provider.dart';
import 'package:focux_app/features/perfil/screens/perfil_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/tolerant_golden_comparator.dart';

final _incompleto = PerfilPersonal(
  id: 7,
  nome: 'Matheus Teste',
  email: 'qa@example.com',
  cref: '123456-G/SP',
  especialidade: 'Quão',
  corPrimaria: '#0B4F5C',
  corSecundaria: '#3F63E4',
  slug: 'personal',
  plano: 'ENTERPRISE',
  instagram: '@haha',
);

final _completo = PerfilPersonal(
  id: 7,
  nome: 'Matheus Teste',
  email: 'qa@example.com',
  telefone: '62982213003',
  cref: '123456-G/SP',
  especialidade: 'Hipertrofia',
  corPrimaria: '#0B4F5C',
  corSecundaria: '#3F63E4',
  slug: 'personal',
  plano: 'ENTERPRISE',
  chavePix: 'qa@example.com',
  descricaoProfissional: 'Especializado em biomecânica.',
  especialidades: 'Hipertrofia',
  instagram: '@qacoach',
  logoUrl: 'https://cdn.example.com/qa-coach.png',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
    // A foto do perfil usa cache em disco; o teste não tem o plugin.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DashboardHomeClientCache.clear();
  });

  final casos = {'incompleto': _incompleto, 'completo': _completo};
  for (final escuro in [false, true]) {
    for (final entry in casos.entries) {
      testWidgets('perfil do personal, ${entry.key} (escuro: $escuro)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final brilho = escuro ? Brightness.dark : Brightness.light;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [perfilProvider.overrideWith((ref) async => entry.value)],
            child: RepaintBoundary(
              key: const ValueKey('tela'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: brilho,
                  colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent, brightness: brilho),
                  useMaterial3: true,
                ),
                locale: const Locale('pt'),
                supportedLocales: S.supportedLocales,
                localizationsDelegates: S.localizationsDelegates,
                home: const PerfilScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        await expectFocuxGolden(
          find.byKey(const ValueKey('tela')),
          'goldens/perfil_personal_${entry.key}_390${escuro ? '_dark' : ''}.png',
        );
        // Sem backend no teste, o ApiClient tenta de novo com espera: deixa esgotar.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(seconds: 5));
        }
      });
    }
  }
}
