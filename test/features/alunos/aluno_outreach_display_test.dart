import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/alunos/utils/aluno_outreach_display.dart';

void main() {
  test('copy da sheet de outreach', () {
    expect(alunoOutreachOpenChatLabel(), 'Abrir chat');
    expect(alunoOutreachCopyLabel(), 'Copiar mensagem');
    expect(alunoOutreachCopySuccess(), 'Mensagem copiada.');
    expect(alunoOutreachFooterHint(), contains('tom'));
  });
}
