@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/ficha_volume.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_choice_strip.dart';
import 'package:focux_app/features/treinos/data/ficha_modelo_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/screens/ficha_modelo_screen.dart';
import 'package:focux_app/features/treinos/widgets/ficha_modelos_aba.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/tolerant_golden_comparator.dart';

class _Repo extends FichaModeloRepository {
  _Repo(this.modelos) : super(ApiClient());

  final List<FichaModelo> modelos;

  @override
  Future<FichaVolume> volumeDoModelo(int id) async =>
      const FichaVolume(totalSeries: 26, grupos: [VolumeGrupo(grupo: 'PEITO', series: 12, exercicios: 3, dias: [1, 4]), VolumeGrupo(grupo: 'COSTAS_LATISSIMO', series: 9, exercicios: 2, dias: [2]), VolumeGrupo(grupo: 'OMBRO_LATERAL', series: 5, exercicios: 1, dias: [4])]);

  @override
  Future<List<FichaModelo>> listar() async => modelos;

  @override
  Future<FichaModelo> buscar(int id) async => modelos.first;
}

const _hipertrofia = FichaModelo(
  id: 31,
  nome: 'Hipertrofia 4 dias',
  itens: [
    FichaModeloItem(descanso: false, treinoId: 1, nome: 'Treino A', diaSemana: 1, exerciciosCount: 5),
    FichaModeloItem(descanso: false, treinoId: 2, nome: 'Treino B', diaSemana: 2, exerciciosCount: 4),
    FichaModeloItem(descanso: true),
    FichaModeloItem(descanso: false, treinoId: 3, nome: 'Treino C', diaSemana: 4, exerciciosCount: 0),
    FichaModeloItem(descanso: false, treinoId: 4, nome: 'Treino D', diaSemana: 5, exerciciosCount: 7),
  ],
);

const _fullBody = FichaModelo(
  id: 32,
  nome: 'Full body 3 dias',
  itens: [
    FichaModeloItem(descanso: false, treinoId: 5, nome: 'Treino A', diaSemana: 1, exerciciosCount: 6),
    FichaModeloItem(descanso: false, treinoId: 6, nome: 'Treino B', diaSemana: 3, exerciciosCount: 6),
    FichaModeloItem(descanso: false, treinoId: 7, nome: 'Treino C', diaSemana: 5, exerciciosCount: 5),
  ],
);

Widget _app(Widget home, {required bool escuro}) {
  final brilho = escuro ? Brightness.dark : Brightness.light;
  return ProviderScope(
    overrides: [
      fichaModeloRepositoryProvider.overrideWithValue(_Repo(const [_hipertrofia, _fullBody])),
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

    testWidgets('lista de modelos, aba Semanas (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: FichaModelosAba(
              abas: FxChoiceStrip<int>(
                itens: const [
                  FxChoiceItem(value: 0, label: 'Semanas'),
                  FxChoiceItem(value: 1, label: 'Sessões'),
                ],
                selecionado: 0,
                onSelecionar: (_) {},
              ),
            ),
          ),
          escuro: escuro,
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await expectFocuxGolden(find.byKey(const ValueKey('tela')), 'goldens/modelos_semanas_390$sufixo.png');
    });

    testWidgets('tela do modelo (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(const FichaModeloScreen(modeloId: 31), escuro: escuro));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await expectFocuxGolden(find.byKey(const ValueKey('tela')), 'goldens/modelo_tela_390$sufixo.png');
    });
  }
}
