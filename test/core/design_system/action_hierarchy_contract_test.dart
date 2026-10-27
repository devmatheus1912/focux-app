import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Telas já migradas para a hierarquia de ações (SPEC-botoes-acoes). A lista
/// cresce a cada rodada; a auditoria do app inteiro é um módulo à parte.
const _migradas = <String>[
  'lib/features/alunos/widgets/aluno_detail_hero_card.dart',
  'lib/features/alunos/widgets/aluno360_timeline_card.dart',
  'lib/features/alunos/widgets/aluno360_ficha_card.dart',
  'lib/features/alunos/widgets/aluno360_copilot_card.dart',
  'lib/features/alunos/widgets/aluno360_copilot_ia_refresh_button.dart',
  'lib/features/treinos/screens/treino_detail_screen_exercises.part.dart',
  'lib/features/exercicios/screens/exercicios_list_screen.dart',
  'lib/features/dashboard/widgets/dashboard_section_header.dart',
  'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
];

void main() {
  test('telas migradas não têm texto solto clicável', () {
    for (final caminho in _migradas) {
      final fonte = File(caminho).readAsStringSync();
      expect(
        fonte.contains(RegExp(r'\bTextButton(\.icon)?\(')),
        isFalse,
        reason: '$caminho: use FxActionLink, FxTonalButton ou o botão cheio',
      );
      expect(
        fonte.contains('TextDecoration.underline'),
        isFalse,
        reason: '$caminho: ação não é texto sublinhado',
      );
    }
  });

  test('as peças da hierarquia existem e garantem 44 de toque', () {
    final link =
        File('lib/core/widgets/fx_action_link.dart').readAsStringSync();
    final tonal =
        File('lib/core/widgets/fx_tonal_button.dart').readAsStringSync();
    expect(link, contains('minHeight: 44'));
    expect(link, contains("'chevron-right'"));
    expect(tonal, contains('alturaToque = 44'));
  });

  test('"Nova mensalidade" é o botão principal do rodapé', () {
    final fonte =
        File(
          'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
        ).readAsStringSync();
    expect(fonte, contains("label: 'Nova mensalidade'"));
    expect(fonte, contains('FxLiquidPrimaryButton('));
  });
}
