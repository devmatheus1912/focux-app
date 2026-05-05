import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aluno detail exposes 360 view and prescriptive copilot actions', () {
    final screen =
        File(
          'lib/features/alunos/screens/aluno_detail_screen.dart',
        ).readAsStringSync();

    expect(screen, contains('class _Aluno360CopilotCard'));
    expect(screen, contains("'Aluno 360'"));
    expect(screen, contains('alunoCopilotoActionProvider'));
    expect(screen, contains('proximaAcao(alunoId)'));
    expect(screen, contains('salvarAcaoCopiloto'));
    expect(screen, contains('commandCenterProvider'));
    expect(screen, contains('class _Aluno360SignalTile'));
    expect(screen, contains('class _CopilotPrescription'));
    expect(screen, contains('Clipboard.setData'));
    expect(screen, contains('_mensagemPronta'));
    expect(screen, contains("'Atribuir'"));
    expect(screen, contains("'Copiar mensagem'"));
    expect(screen, contains("'Mensagem'"));
    expect(screen, contains("'Evoluir treino'"));
    expect(screen, contains('perfil, autonomia, financeiro'));
  });
}
