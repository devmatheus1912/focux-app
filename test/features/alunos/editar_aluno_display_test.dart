import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/editar_aluno_display.dart';

void main() {
  test('editar aluno display em PT-BR', () {
    expect(editarAlunoHubSubtitle(), 'Perfil do aluno');
    expect(editarAlunoSalvarTooltip(), 'Salvar');
    expect(editarAlunoConfirmLabel(), 'Salvar');
    expect(editarAlunoConfirmTitle('Beatriz'), 'Salvar Beatriz?');
    expect(editarAlunoConfirmMessage(), contains('360'));
    expect(editarAlunoTelefoneMax, 20);
    expect(addAlunoFirstName('Beatriz Andrade'), 'Beatriz');
    expect(addAlunoEmailValido('a@b.com'), isTrue);
  });
}
