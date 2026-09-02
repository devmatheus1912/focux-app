import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/add_aluno_display.dart';

void main() {
  test('add aluno display valida e-mail e primeiro nome', () {
    expect(addAlunoEmailValido('aluno@email.com'), isTrue);
    expect(addAlunoEmailValido('  '), isFalse);
    expect(addAlunoEmailValido('sem-arroba'), isFalse);
    expect(addAlunoFirstName(''), 'Aluno');
    expect(addAlunoFirstName('  Beatriz Andrade'), 'Beatriz');
    expect(addAlunoHubSubtitle(), 'Cadastro rápido');
    expect(addAlunoSalvarTooltip(), 'Cadastrar');
    expect(addAlunoNomeMax, 150);
  });

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
      contains('copia o convite'),
    );
    expect(addAlunoTiposConsultoria, containsAll(['ONLINE', 'HIBRIDO']));
  });
}
