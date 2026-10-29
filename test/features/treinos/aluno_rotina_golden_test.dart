@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/ficha_volume.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/aluno_rotina_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/tolerant_golden_comparator.dart';

class _Repo extends TreinoRepository {
  _Repo(this.fila) : super(ApiClient());

  final RotinaFila fila;

  @override
  Future<FichaVolume> volumeDaFicha(int alunoId) async =>
      const FichaVolume(totalSeries: 26, grupos: [VolumeGrupo(grupo: 'PEITO', series: 12, exercicios: 3, dias: [1, 4]), VolumeGrupo(grupo: 'COSTAS_LATISSIMO', series: 9, exercicios: 2, dias: [2]), VolumeGrupo(grupo: 'OMBRO_LATERAL', series: 5, exercicios: 1, dias: [4])]);

  @override
  Future<RotinaFila> buscarRotina(int alunoId) async => fila;
}

const _fila = RotinaFila(
  itens: [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 1, nome: 'Treino A', diaSemana: 1, exerciciosCount: 5),
    RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 2, nome: 'Treino B', diaSemana: 2, exerciciosCount: 0),
    RotinaItem(id: 3, tipo: RotinaItemTipo.treino, treinoId: 3, nome: 'Treino C', diaSemana: 4, exerciciosCount: 6),
    RotinaItem(id: 4, tipo: RotinaItemTipo.treino, treinoId: 4, nome: 'Posterior', diaSemana: 4, exerciciosCount: 3),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
    SharedPreferences.setMockInitialValues({});
  });

  for (final escuro in [false, true]) {
    for (final vazia in [false, true]) {
      testWidgets('ficha do aluno (escuro: $escuro, vazia: $vazia)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final brilho = escuro ? Brightness.dark : Brightness.light;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              treinoRepositoryProvider.overrideWithValue(
                _Repo(vazia ? RotinaFila.vazia : _fila),
              ),
              fichaModelosProvider.overrideWith((ref) async => const []),
            ],
            child: RepaintBoundary(
              key: const ValueKey('ficha'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: brilho,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: EagleTokens.brandAccent,
                    brightness: brilho,
                  ),
                  useMaterial3: true,
                ),
                locale: const Locale('pt'),
                supportedLocales: S.supportedLocales,
                localizationsDelegates: S.localizationsDelegates,
                home: const AlunoRotinaScreen(alunoId: 3, alunoNome: 'Hugo'),
              ),
            ),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        await expectFocuxGolden(
          find.byKey(const ValueKey('ficha')),
          'goldens/ficha_aluno_390${vazia ? '_vazia' : ''}${escuro ? '_dark' : ''}.png',
        );
      });
    }
  }
}
