@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/alunos_list_screen.dart';
import 'package:focux_app/features/alunos/utils/alunos_home_client_cache.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/tolerant_golden_comparator.dart';

AlunosHomeBundle _home(List<Aluno> alunos, AlunosStats stats) => AlunosHomeBundle(
  alunos: alunos,
  stats: stats,
  alertasConfig: AlertasConfiguracao(diasSemTreino: 7, aderenciaMinima: 50),
  page: AlunosHomePageMeta(
    page: 0,
    size: 40,
    totalElements: alunos.length,
    totalPages: 1,
    hasNext: false,
  ),
);

final _cheia = _home(
  [
    Aluno(id: 1, nome: 'Hugo Lima', email: 'h***@test.com', status: 'ATIVO', emRisco: true, contaAtiva: true, diasSemTreino: 9),
    Aluno(id: 2, nome: 'guilherme -', email: 'g***@test.com', status: 'ATIVO', contaAtiva: false),
    Aluno(id: 3, nome: 'Ana Souza', email: 'a***@test.com', status: 'ATIVO', objetivo: 'Força', contaAtiva: true, diasSemTreino: 1),
    Aluno(id: 4, nome: 'Matheus Aluno', email: 'm***@test.com', status: 'ATIVO', objetivo: 'hipertrofia', contaAtiva: true, diasSemTreino: 0),
  ],
  const AlunosStats(
    total: 4,
    totalAtivos: 4,
    totalInadimplentes: 0,
    totalRiscoAlto: 1,
    totalConvites: 1,
    totalContatoHoje: 1,
  ),
);

final _vazia = _home(
  const [],
  const AlunosStats(
    total: 0,
    totalAtivos: 0,
    totalInadimplentes: 0,
    totalRiscoAlto: 0,
    totalConvites: 0,
    totalContatoHoje: 0,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  setUp(() {
    AlunosPendingSearch.consume();
    SharedPreferences.setMockInitialValues({});
    AlunosHomeClientCache.clear();
  });

  final casos = {'cheia': _cheia, 'vazia': _vazia};
  for (final escuro in [false, true]) {
    for (final entry in casos.entries) {
      testWidgets('lista de alunos, ${entry.key} (escuro: $escuro)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 760));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final brilho = escuro ? Brightness.dark : Brightness.light;
        final router = GoRouter(
          initialLocation: '/alunos',
          routes: [
            GoRoute(path: '/alunos', builder: (_, __) => const AlunosListScreen()),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [alunosHomeProvider.overrideWith((ref) async => entry.value)],
            child: RepaintBoundary(
              key: const ValueKey('tela'),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: brilho,
                  colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent, brightness: brilho),
                  useMaterial3: true,
                ),
                locale: const Locale('pt'),
                supportedLocales: S.supportedLocales,
                localizationsDelegates: S.localizationsDelegates,
                routerConfig: router,
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
          'goldens/alunos_lista_${entry.key}_390${escuro ? '_dark' : ''}.png',
        );
        // Sem backend no teste, o ApiClient tenta de novo com espera: deixa esgotar.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(seconds: 5));
        }
      });
    }
  }
}
