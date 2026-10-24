@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/ficha_historico_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_historico.dart';
import 'package:focux_app/features/treinos/providers/ficha_historico_provider.dart';
import 'package:focux_app/features/treinos/screens/ficha_anterior_screen.dart';
import 'package:focux_app/features/treinos/screens/fichas_anteriores_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/tolerant_golden_comparator.dart';

class _Repo extends FichaHistoricoRepository {
  _Repo(this.fichas) : super(ApiClient());

  final List<FichaHistorico> fichas;

  @override
  Future<List<FichaHistorico>> listar(int alunoId) async => fichas;

  @override
  Future<FichaHistorico> buscar(int alunoId, int fichaId) async => fichas.first;
}

final _fichas = [
  FichaHistorico(
    id: 7,
    motivo: MotivoTroca.recomecada,
    vigenciaInicio: DateTime(2026, 8, 12),
    vigenciaFim: DateTime(2026, 10, 14),
    encerradaEm: DateTime(2026, 10, 14, 9),
    sessoes: 4,
    exercicios: 22,
    itens: const [
      FichaHistoricoItem(descanso: false, treinoId: 1, nome: 'Treino A', diaSemana: 1, exerciciosCount: 6, disponivel: true),
      FichaHistoricoItem(descanso: false, treinoId: 2, nome: 'Treino B', diaSemana: 2, exerciciosCount: 5, disponivel: true),
      FichaHistoricoItem(descanso: true),
      FichaHistoricoItem(descanso: false, treinoId: 3, nome: 'Treino C', diaSemana: 4, exerciciosCount: 6, disponivel: true),
      FichaHistoricoItem(descanso: false, nome: 'Posterior', diaSemana: 5, exerciciosCount: 5),
    ],
  ),
  FichaHistorico(
    id: 6,
    motivo: MotivoTroca.modelo,
    nomeModelo: 'Hipertrofia 4 dias',
    encerradaEm: DateTime(2026, 8, 11, 9),
    sessoes: 3,
    exercicios: 16,
  ),
  FichaHistorico(
    id: 5,
    motivo: MotivoTroca.duplicada,
    vigenciaInicio: DateTime(2026, 5, 2),
    vigenciaFim: DateTime(2026, 6, 27),
    encerradaEm: DateTime(2026, 6, 27, 9),
    sessoes: 3,
    exercicios: 15,
  ),
];

Widget _app(Widget home, {required bool escuro}) {
  final brilho = escuro ? Brightness.dark : Brightness.light;
  return ProviderScope(
    overrides: [fichaHistoricoRepositoryProvider.overrideWithValue(_Repo(_fichas))],
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
        home: home,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
    SharedPreferences.setMockInitialValues({});
  });

  for (final escuro in [false, true]) {
    final sufixo = escuro ? '_dark' : '';

    testWidgets('lista de fichas anteriores (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(const FichasAnterioresScreen(alunoId: 3, alunoNome: 'Hugo'), escuro: escuro),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/fichas_anteriores_390$sufixo.png',
      );
    });

    testWidgets('uma ficha anterior (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          const FichaAnteriorScreen(alunoId: 3, alunoNome: 'Hugo', fichaId: 7),
          escuro: escuro,
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/ficha_anterior_390$sufixo.png',
      );
    });
  }
}
