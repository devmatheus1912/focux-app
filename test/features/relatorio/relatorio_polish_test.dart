import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('relatorio global e PDF usam polish; o do aluno mora na Aderência', () {
    final global = readScreenSourceBundle(
      'lib/features/relatorio/screens/relatorio_global_screen.dart',
    );
    final pdf = readScreenSourceBundle(
      'lib/features/relatorio/utils/relatorio_pdf_export.dart',
    );

    // O Relatório do aluno saiu: período, comparação e PDF ficam na Aderência.
    expect(
      File('lib/features/relatorio/screens/relatorio_screen.dart').existsSync(),
      isFalse,
    );
    expect(global, contains("'/alunos/\${aluno.alunoId}/engajamento'"));

    expect(pdf, contains('focuxPdfPage'));
    expect(pdf, contains('brand: brand'));
    expect(pdf, isNot(contains('PdfColor.fromInt')));
    // "Check-ins" é o mesmo número de "Dias com treino": não repete no PDF.
    expect(pdf, isNot(contains("'Check-ins'")));

    expect(global, contains('fxScreenA11yScope'));
    expect(global, isNot(contains('FxSettingsGroup')));
    expect(global, contains('OperationalMetricTile'));
    expect(global, contains('FxHelpIconButton'));
    expect(global, contains('relatoriosHubViewed'));
    expect(global, isNot(contains('dashboardHeroCaptionOnTeal')));
    expect(global, isNot(contains('Colors.white70')));
  });
}
