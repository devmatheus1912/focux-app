@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_action_link.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_home_header.dart';
import 'package:focux_app/features/exercicios/models/exercicio_criado.dart';
import 'package:focux_app/features/exercicios/widgets/exercicio_criado_sheet.dart';
import 'package:focux_app/features/financeiro/widgets/dia_vencimento_grade.dart';
import 'package:focux_app/features/financeiro/widgets/vencimento_escolha.dart';
import 'package:focux_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/tolerant_golden_comparator.dart';

Widget _app(Widget home, {bool dark = false}) => ProviderScope(
  overrides: [notificacoesNaoLidasProvider.overrideWith((ref) async => 0)],
  child: MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: EagleTokens.brandAccent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
    ),
    locale: const Locale('pt'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: S.localizationsDelegates,
    home: home,
  ),
);

Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  Future<void> tela(WidgetTester tester, Size tamanho) async {
    await tester.binding.setSurfaceSize(tamanho);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('cabeçalho da Hoje com Conversas (claro)', (tester) async {
    await tela(tester, const Size(390, 180));
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: DashboardHomeHeader(
            nomePersonal: 'Matheus Ribeiro',
            logoUrl: null,
            isDark: false,
            primary: EagleTokens.brandAccent,
            onProfileTap: () {},
            onHelp: () {},
            onQuickSearch: () {},
            onConversas: () {},
            conversasCount: 4,
          ),
        ),
      ),
    );
    await _assentar(tester);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/header_conversas_390.png',
    );
  });

  testWidgets('cabeçalho da Hoje com Conversas (escuro, >9)', (tester) async {
    await tela(tester, const Size(390, 180));
    await tester.pumpWidget(
      _app(
        dark: true,
        Scaffold(
          body: DashboardHomeHeader(
            nomePersonal: 'Matheus Ribeiro',
            logoUrl: null,
            isDark: true,
            primary: EagleTokens.brandAccent,
            onProfileTap: () {},
            onHelp: () {},
            onQuickSearch: () {},
            onConversas: () {},
            conversasCount: 14,
          ),
        ),
      ),
    );
    await _assentar(tester);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/header_conversas_390_dark.png',
    );
  });

  testWidgets('peças de ação: link com seta e botão tonal', (tester) async {
    await tela(tester, const Size(390, 220));
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FxActionLink(label: 'Ver todos os 6 sinais', onTap: () {}),
                const SizedBox(height: 8),
                FxTonalButton(
                  label: 'Montar ficha',
                  icon: Icons.add_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: 8),
                FxTonalButton(
                  label: 'Definir',
                  icon: Icons.flag_outlined,
                  compact: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await _assentar(tester);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/pecas_de_acao_390.png',
    );
  });

  testWidgets('folha "Exercício criado" (do treino)', (tester) async {
    await tela(tester, const Size(390, 700));
    await tester.pumpWidget(
      _app(
        Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => showExercicioCriadoSheet(
                          context,
                          nome: 'Crucifixo inverso na máquina (meu)',
                          origem: ExercicioOrigem.treino,
                        ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _assentar(tester);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/exercicio_criado_390.png',
    );
  });

  testWidgets('grade do dia do vencimento', (tester) async {
    await tela(tester, const Size(390, 700));
    await tester.pumpWidget(
      _app(
        Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => showDiaVencimentoSheet(
                          context,
                          titulo: 'Dia do vencimento',
                          selecionado: 7,
                          maximo: 28,
                          hoje: DateTime(2026, 10, 27),
                        ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _assentar(tester);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/dia_vencimento_grade_390.png',
    );
  });

  testWidgets('folha de vencimento com data passada', (tester) async {
    await tela(tester, const Size(390, 900));
    await tester.pumpWidget(
      _app(
        Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => showVencimentoSheet(
                          context,
                          mesReferencia: DateTime(2026, 10, 1),
                          atual: DateTime(2026, 10, 10),
                          hoje: DateTime(2026, 10, 27),
                        ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _assentar(tester);
    await expectFocuxGolden(
      find.byType(MaterialApp),
      'goldens/vencimento_passado_390.png',
    );
  });
}
