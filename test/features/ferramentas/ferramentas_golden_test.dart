@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:focux_app/features/ferramentas/providers/ferramentas_catalogo_provider.dart';
import 'package:focux_app/features/ferramentas/screens/ferramentas_screen.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/riverpod_seeds.dart';
import '../../support/tolerant_golden_comparator.dart';

class _Catalogo extends FerramentasCatalogoNotifier {
  @override
  Future<FerramentasCatalogo> build() async => FerramentasCatalogo.fromJson({
    'version': 1,
    'hubs': [
      {
        'id': 'operacao',
        'titulo': 'Operação',
        'itens': [
          {'id': 'exercicios', 'titulo': 'Exercícios', 'subtitulo': 'Sua biblioteca de movimentos', 'rotaApp': '/exercicios', 'unlocked': true},
          {'id': 'feed', 'titulo': 'Feed', 'subtitulo': 'Novidades para os alunos', 'rotaApp': '/feed', 'unlocked': true},
          {'id': 'habitos', 'titulo': 'Hábitos', 'rotaApp': '/habitos', 'unlocked': true},
          {'id': 'desafios', 'titulo': 'Desafios', 'rotaApp': '/desafios', 'unlocked': true},
        ],
      },
      {
        'id': 'captacao',
        'titulo': 'Captação',
        'itens': [
          {'id': 'captacao', 'titulo': 'Captação', 'subtitulo': 'Leads públicos e landing', 'rotaApp': '/leads-publicos', 'unlocked': true},
        ],
      },
      {
        'id': 'vendas',
        'titulo': 'Vendas',
        'itens': [
          {'id': 'vendas', 'titulo': 'Vendas', 'subtitulo': 'Pacotes e loja', 'rotaApp': '/pacotes', 'unlocked': true},
          {'id': 'ofertas', 'titulo': 'Ofertas', 'rotaApp': '/ofertas-upsell', 'unlocked': false, 'upgradePlano': 'ENTERPRISE'},
        ],
      },
    ],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
    SharedPreferences.setMockInitialValues({});
  });

  for (final escuro in [false, true]) {
    testWidgets('tela Ferramentas (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const features = PlanoFeatures(
        plano: SubscriptionPlan.PRO,
        financeiro: true,
        agenda: true,
        relatorios: true,
        whiteLabel: false,
        iaCopiloto: true,
        migracaoFoto: false,
      );
      final brilho = escuro ? Brightness.dark : Brightness.light;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seededPlanoFeatures(features),
            ferramentasCatalogoProvider.overrideWith(_Catalogo.new),
          ],
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
              home: const FerramentasScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/ferramentas_390${escuro ? '_dark' : ''}.png',
      );
    });
  }
}
