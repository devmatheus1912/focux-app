import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/add_aluno_display.dart';

void main() {
  test('add aluno confirm e copy pós-cadastro', () {
    expect(addAlunoConfirmTitle('Beatriz'), 'Cadastrar Beatriz?');
    expect(addAlunoConfirmLabel(), 'Cadastrar');
    expect(
      addAlunoConfirmMessage(hasWhatsapp: true),
      contains('WhatsApp'),
    );
    expect(
      addAlunoConfirmMessage(hasWhatsapp: false),
      contains('copia o convite'),
    );
    expect(
      addAlunoAfterSubmitCopy(firstName: 'Beatriz', hasWhatsapp: true),
      contains('WhatsApp'),
    );
    expect(
      addAlunoAfterSubmitCopy(firstName: 'Beatriz', hasWhatsapp: false),
      contains('copia o link'),
    );
    expect(addAlunoTiposConsultoria, containsAll(['ONLINE', 'HIBRIDO']));
  });
}
