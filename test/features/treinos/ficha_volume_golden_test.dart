@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/models/ficha_volume.dart';
import 'package:focux_app/features/treinos/providers/ficha_volume_provider.dart';
import 'package:focux_app/features/treinos/widgets/ficha_volume_secao.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

const _volume = FichaVolume(
  totalSeries: 36,
  grupos: [
    VolumeGrupo(grupo: 'PEITO', series: 14, exercicios: 3, dias: [1, 4]),
    VolumeGrupo(grupo: 'COSTAS_LATISSIMO', series: 9, exercicios: 2, dias: [2]),
    VolumeGrupo(grupo: 'TRAPEZIO', series: 3, exercicios: 1, dias: [2, 5]),
    VolumeGrupo(grupo: 'QUADRICEPS', series: 6, exercicios: 2, dias: [3]),
    VolumeGrupo(grupo: 'OMBRO_LATERAL', series: 4, exercicios: 1, dias: [4]),
  ],
  seriesSemGrupo: 2,
  exerciciosSemGrupo: 1,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  for (final escuro in [false, true]) {
    testWidgets('seção de volume aberta (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final brilho = escuro ? Brightness.dark : Brightness.light;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fichaVolumeProvider(3).overrideWith((ref) async => _volume)],
          child: RepaintBoundary(
            key: const ValueKey('volume'),
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
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FichaVolumeSecao(provider: fichaVolumeProvider(3), origem: 'ficha'),
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await tester.tap(find.text('Volume da semana'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await expectFocuxGolden(
        find.byKey(const ValueKey('volume')),
        'goldens/ficha_volume_390${escuro ? '_dark' : ''}.png',
      );
    });
  }
}
