import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ranking não tem frase de UI no arquivo da tela', () {
    final frase = RegExp(r"'[^'$\n]*[A-Za-zÀ-ú]{2,} [A-Za-zÀ-ú]{2,}[^'\n]*'");
    final rotulo = RegExp(
      r"(?:label|title|subtitle|tooltip|message):\s*'|Text\(\s*'",
    );
    const path = 'lib/features/ranking/screens/ranking_screen.dart';
    final src = File(path).readAsStringSync();
    expect(frase.allMatches(src), isEmpty, reason: path);
    expect(rotulo.hasMatch(src), isFalse, reason: path);
  });

  test('arquivos fatiados ficam abaixo de 500 linhas', () {
    for (final path in [
      'lib/features/alunos/data/aluno_repository.dart',
      'lib/features/alunos/data/aluno_core_models.dart',
      'lib/features/alunos/data/aluno_360_models.dart',
      'lib/features/alunos/data/aluno_home_models.dart',
      'lib/features/alunos/data/aluno_models.dart',
      'lib/features/treinos/widgets/prescription_editor_rows.part.dart',
      'lib/features/treinos/widgets/prescription_editor_sheet.dart',
      'lib/features/treinos/widgets/prescription_editor_body.part.dart',
      'lib/features/treinos/widgets/prescription_editor_pickers.part.dart',
      'lib/features/treinos/widgets/prescription_editor_copy.dart',
      'lib/features/alunos/utils/aluno360_operacao_logic.dart',
      'lib/features/alunos/utils/aluno360_operacao_logic_format.part.dart',
      'lib/features/alunos/utils/aluno360_operacao_logic_visibility.part.dart',
      'lib/features/alunos/utils/aluno360_operacao_logic_snapshot.part.dart',
      'lib/features/retencao/screens/churn_dashboard_screen.dart',
      'lib/features/retencao/screens/churn_dashboard_screen_cards.part.dart',
    ]) {
      expect(
        File(path).readAsLinesSync().length,
        lessThan(500),
        reason: path,
      );
    }
  });

  test('churn dashboard não tem frase de UI no arquivo da tela', () {
    final frase = RegExp(r"'[^'$\n]*[A-Za-zÀ-ú]{2,} [A-Za-zÀ-ú]{2,}[^'\n]*'");
    const path = 'lib/features/retencao/screens/churn_dashboard_screen.dart';
    final src = File(path).readAsStringSync();
    expect(frase.allMatches(src), isEmpty, reason: path);
  });

  test('ranking_screen source bundle usa as constantes de copy', () {
    final screen = readScreenSourceBundle(
      'lib/features/ranking/screens/ranking_screen.dart',
    );
    expect(screen, contains('rankingComoCalculamos'));
    expect(screen, contains('rankingPodioExplicacao'));
    expect(screen, isNot(contains('desconto na assinatura')));
  });
}
