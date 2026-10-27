import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Folhas já migradas para o kit (rodada "treino"). A auditoria do app inteiro
/// é um módulo à parte; esta lista cresce conforme as folhas migram.
const _migradas = <String, List<String>>{
  'lib/features/alunos/widgets/aluno360_commitment_sheet.dart': [
    'FxSheetFrame',
    'FxQuickChips',
    'FxLiquidPrimaryButton',
  ],
  'lib/features/alunos/widgets/aluno_outreach_message_sheet.dart': [
    'FxSheetFrame',
    'FxLiquidPrimaryButton',
  ],
  'lib/features/treinos/screens/treino_detail_screen_exercises.part.dart': [
    'showFxGroupedActionSheet',
  ],
  'lib/features/exercicios/widgets/add_exercicio_filters_sheet.dart': [
    'FxSheetSearchField',
    'FxHomeSheetHeader',
  ],
  'lib/features/treinos/widgets/prescription_editor_body.part.dart': [
    'FxQuickChips',
    'FxHomeSheetHeader',
  ],
};

void main() {
  test('folhas migradas usam as peças do kit', () {
    _migradas.forEach((caminho, pecas) {
      final fonte = File(caminho).readAsStringSync();
      for (final peca in pecas) {
        expect(fonte, contains(peca), reason: '$caminho deve usar $peca');
      }
    });
  });

  test('nenhuma folha migrada tem botão cheio vermelho para ação destrutiva', () {
    for (final caminho in _migradas.keys) {
      final fonte = File(caminho).readAsStringSync();
      final vermelhoCheio = RegExp(
        r'ElevatedButton[\s\S]{0,200}backgroundColor:\s*EagleTokens\.bad',
      );
      expect(
        vermelhoCheio.hasMatch(fonte),
        isFalse,
        reason: '$caminho: ação destrutiva é linha de texto, não botão cheio',
      );
    }
  });

  test('o vídeo e a lista do treino não têm botão destrutivo cheio', () {
    for (final caminho in [
      'lib/features/treinos/widgets/treino_prescription_video_block.dart',
      'lib/features/treinos/widgets/treino_inset_sheet.dart',
    ]) {
      final fonte = File(caminho).readAsStringSync();
      if (caminho.endsWith('treino_inset_sheet.dart')) {
        // só a confirmação (TreinoInsetConfirmSheet) mantém o botão cheio
        final antes = fonte.split('class TreinoInsetConfirmSheet').first;
        expect(antes.contains('ElevatedButton'), isFalse, reason: caminho);
      } else {
        expect(fonte.contains('ElevatedButton'), isFalse, reason: caminho);
      }
    }
  });

  test('as peças do kit existem', () {
    for (final arquivo in [
      'fx_sheet_frame.dart',
      'fx_grouped_action_sheet.dart',
      'fx_sheet_search_field.dart',
      'fx_quick_chips.dart',
    ]) {
      expect(File('lib/core/widgets/$arquivo').existsSync(), isTrue, reason: arquivo);
    }
  });
}
