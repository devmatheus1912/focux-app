@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_choice_chip.dart';
import 'package:focux_app/core/widgets/fx_choice_strip.dart';
import 'package:focux_app/core/widgets/fx_day_row.dart';
import 'package:focux_app/core/widgets/fx_status_pill.dart';
import 'package:focux_app/core/widgets/fx_tap_row.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';
import 'fx_kit_host.dart';

Widget _galeria() => Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FxChoiceStrip<int>(
        itens: const [
          FxChoiceItem(value: 2, label: '2'),
          FxChoiceItem(value: 3, label: '3'),
          FxChoiceItem(value: 4, label: '4'),
          FxChoiceItem(value: 5, label: '5'),
          FxChoiceItem(value: 6, label: '6'),
        ],
        selecionado: 4,
        onSelecionar: (_) {},
      ),
      const SizedBox(height: 12),
      const Wrap(
        spacing: 8,
        children: [
          FxStatusPill(label: 'Pronto', tone: FxPillTone.success),
          FxStatusPill(label: 'Em montagem', tone: FxPillTone.warning),
          FxStatusPill(label: 'Vence em 7 dias', tone: FxPillTone.accent),
          FxStatusPill(label: 'Vencida', tone: FxPillTone.danger),
          FxStatusPill(label: 'Rascunho'),
        ],
      ),
      const SizedBox(height: 12),
      FxDayRow(
        dia: 'Seg',
        hoje: true,
        hojeLabel: 'Hoje',
        descansoLabel: 'Descanso',
        adicionarLabel: 'Adicionar treino',
        segundoTreinoLabel: '2º treino',
        sessoes: [FxDaySession(nome: 'Treino A', detalhe: '5 exercícios', onTap: () {})],
      ),
      const SizedBox(height: 8),
      FxDayRow(
        dia: 'Ter',
        descansoLabel: 'Descanso',
        adicionarLabel: 'Adicionar treino',
        segundoTreinoLabel: '2º treino',
        sessoes: [
          FxDaySession(nome: 'Treino B', detalhe: 'Vazio', fim: const FxStatusPill(label: 'Montar', tone: FxPillTone.warning), onTap: () {}),
          FxDaySession(nome: 'Posterior', detalhe: '3 exercícios', onTap: () {}),
        ],
      ),
      const SizedBox(height: 8),
      FxDayRow(
        dia: 'Qua',
        descansoLabel: 'Descanso',
        adicionarLabel: 'Adicionar treino',
        segundoTreinoLabel: '2º treino',
        sessoes: const [],
        onAdicionar: () {},
      ),
      const SizedBox(height: 8),
      FxTapRow(title: 'Treino C', subtitle: '6 exercícios', onTap: () {}),
      const SizedBox(height: 8),
      Row(
        children: [
          FxChoiceChip(label: 'A', selected: true, onTap: () {}),
          FxChoiceChip(label: 'B', selected: false, onTap: () {}),
        ],
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  for (final escuro in [false, true]) {
    testWidgets('galeria do kit da ficha (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('galeria'),
          child: kitHost(_galeria(), dark: escuro),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectFocuxGolden(
        find.byKey(const ValueKey('galeria')),
        'goldens/fx_ficha_kit_390${escuro ? '_dark' : ''}.png',
      );
    });
  }
}
