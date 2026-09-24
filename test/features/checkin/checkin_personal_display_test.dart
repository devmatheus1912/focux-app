import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_personal_home.dart';
import 'package:focux_app/features/checkin/utils/checkin_personal_display.dart';

void main() {
  CheckinPersonalItem item({required int alunoId, required String nome}) {
    return CheckinPersonalItem(
      id: alunoId,
      alunoId: alunoId,
      alunoNome: nome,
      treinoNome: 'Full',
    );
  }

  test('foco abre o último aluno; vazio vai para a lista', () {
    expect(checkinComoCalculamos, contains('concluídos hoje'));
    expect(checkinPrimeiroNome('Ana Silva'), 'Ana');
    expect(
      checkinFocusAction(
        const CheckinPersonalHomeBundle(checkinsHoje: 0, hoje: [], semana: []),
      ).label,
      'Ver alunos',
    );

    final hoje = checkinFocusAction(
      CheckinPersonalHomeBundle(
        checkinsHoje: 1,
        hoje: [item(alunoId: 3, nome: 'Ana Silva')],
        semana: const [],
      ),
    );
    expect(hoje.label, 'Ver aluno');
    expect(hoje.alunoId, 3);

    final semana = checkinFocusAction(
      CheckinPersonalHomeBundle(
        checkinsHoje: 0,
        hoje: const [],
        semana: [item(alunoId: 8, nome: 'Bia')],
      ),
    );
    expect(semana.label, 'Ver alunos');
    expect(semana.alunoId, isNull);

    final variosHoje = checkinFocusAction(
      CheckinPersonalHomeBundle(
        checkinsHoje: 2,
        hoje: [
          item(alunoId: 3, nome: 'Ana Silva'),
          item(alunoId: 8, nome: 'Bia'),
        ],
        semana: const [],
      ),
    );
    expect(variosHoje.label, 'Ver Ana');
    expect(variosHoje.alunoId, 3);
  });
}
