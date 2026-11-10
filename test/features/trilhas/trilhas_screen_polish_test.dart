import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Redesign de 10/11/2026: trilha é caminho em etapas, mesmas peças nos dois lados.
void main() {
  test('personal: título, um botão, sem cartões de número nem tipo de meta', () {
    final screen = readScreenSourceBundle(
      'lib/features/trilhas/screens/trilhas_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains("title: 'Trilhas'"));
    expect(screen, contains("label: 'Nova trilha'"));
    expect(screen, contains('showTrilhaFormSheet'));
    expect(screen, contains('showTrilhaDetalhe'));
    expect(screen, contains('TrilhaCartao'));
    for (final saiu in [
      'ShellHeaderIconButton',
      'OperationalMetricTile',
      'FxHubHeader',
      "label: 'Lista'",
      'atualizarProgresso',
      'Atribuir trilha',
      'Trilhas de Progresso',
    ]) {
      expect(screen, isNot(contains(saiu)), reason: saiu);
    }
  });

  test('aluno usa o mesmo cartão e o mesmo detalhe', () {
    final aluno = File(
      'lib/features/trilhas/screens/aluno_trilhas_screen.dart',
    ).readAsStringSync();
    expect(aluno, contains('TrilhasLista'));
    expect(aluno, contains('doPersonal: false'));
    expect(aluno, contains('chatAlunoRascunhoProvider'));
    expect(aluno, isNot(contains('OperationalMetricTile')));
    expect(aluno, isNot(contains('Ir aos treinos')));
  });

  test('formulário sem tipo de meta, com modelos e calendário', () {
    final form = File(
      'lib/features/trilhas/widgets/trilha_form_sheet.dart',
    ).readAsStringSync();
    expect(form, contains('trilhaModelos'));
    expect(form, contains('showFxCalendarioSheet'));
    expect(form, isNot(contains('Tipo de meta')));
    expect(form, isNot(contains('Customizado')));
  });

  test('detalhe: Consegui do aluno e desfazer', () {
    final det = File(
      'lib/features/trilhas/widgets/trilha_detalhe_sheet.dart',
    ).readAsStringSync();
    expect(det, contains("'Consegui'"));
    expect(det, contains('reabrirMarco'));
    expect(det, contains('removerMarco'));
    expect(det, contains('showSuccessAction'));
  });
}
