import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_page.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/providers/exercicio_picker_provider.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/treino_detail_screen.dart';
import 'package:focux_app/features/treinos/utils/treino_criacao_fluxo.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTreinoRepository extends TreinoRepository {
  _FakeTreinoRepository() : super(ApiClient());
}

final _treinoMontado = Treino(
  id: 12,
  nome: 'Treino Hipertrofia',
  exercicios: [
    TreinoExercicioItem(
      id: 1,
      exercicio: Exercicio(
        id: 11,
        nome: 'Supino reto',
        grupoMuscularPrimario: GrupoMuscular.peito,
      ),
      series: 3,
      repeticoes: '10-12',
      descansoSegundos: 60,
      ordem: 0,
    ),
  ],
);

Future<void> _pumpFluxo(
  WidgetTester tester,
  GoRouter router,
  _FakeTreinoRepository repo, {
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...extra,
        treinoRepositoryProvider.overrideWithValue(repo),
        treinoProvider.overrideWith((ref, id) async => _treinoMontado),
        treinoPickerHomeProvider(12).overrideWith(
          (ref) async => TreinoPickerHomeBundle(
            treino: _treinoMontado,
            libraryCount: 2,
            shortcuts: const [],
            uiHints: TreinoPickerUiHints.fallback(librarySize: 2),
          ),
        ),
        exercicioPickerPageProvider.overrideWith(
          (ref, query) async => ExercicioPickerPage(
            content: [Exercicio(id: 1, nome: 'Supino reto')],
            meta: const ExercicioPageMeta(
              page: 0,
              size: 30,
              totalElements: 1,
              totalPages: 1,
              hasNext: false,
            ),
          ),
        ),
        exercicioPickerStatsProvider.overrideWith(
          (ref) async =>
              const ExercicioPickerStats(total: 1, porGrupo: {'PEITO': 1}),
        ),
      ],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  test('extra ida e volta preserva aluno, bloco e modelo', () {
    final extra =
        const TreinoRouteExtra(alunoId: 5, alunoNome: 'Aluno', bloco: 'AQUECIMENTO', modeloId: 3).toExtra();
    final lido = TreinoRouteExtra.parse(extra);
    expect(lido.alunoId, 5);
    expect(lido.alunoNome, 'Aluno');
    expect(lido.bloco, 'AQUECIMENTO');
    expect(lido.modeloId, 3);
    expect(const TreinoRouteExtra().toExtra(), isNull);
    expect(TreinoRouteExtra.parse({'alunoId': '7'}).alunoId, 7);
  });

  testWidgets('menu do detalhe na biblioteca: aplicar (cópia), duplicar, sem template', (tester) async {
    final router = GoRouter(
      initialLocation: '/treinos/12',
      routes: [
        GoRoute(
          path: '/treinos/:id',
          builder: (context, state) => const TreinoDetailScreen(treinoId: 12),
        ),
      ],
    );
    await _pumpFluxo(tester, router, _FakeTreinoRepository());

    expect(
      find.widgetWithText(FxLiquidPrimaryButton, 'Adicionar exercício'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Opções do treino'));
    await _settle(tester);

    expect(find.text('Aplicar na ficha de um aluno'), findsOneWidget);
    expect(
      find.text('Cópia só do aluno: o original não muda'),
      findsOneWidget,
    );
    expect(find.text('Duplicar sessão'), findsOneWidget);
    expect(find.text('Renomear sessão'), findsOneWidget);
    expect(find.text('Excluir treino'), findsOneWidget);
    expect(find.text('Copiar para aluno'), findsNothing);
    expect(find.text('Salvar como template'), findsNothing);
    expect(find.text('Tirar da ficha'), findsNothing);
  });
}
