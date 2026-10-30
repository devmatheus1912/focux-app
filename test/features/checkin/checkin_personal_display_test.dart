import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_personal_display.dart';
import 'package:focux_app/features/checkin/models/checkin_personal_home.dart';

void main() {
  CheckinPersonalItem item({required int alunoId, required String nome}) {
    return CheckinPersonalItem(
      id: alunoId,
      alunoId: alunoId,
      alunoNome: nome,
      treinoNome: 'Full',
    );
  }

  test('aluno com vários treinos aparece uma vez', () {
    final grupos = checkinPorAluno([
      item(alunoId: 1, nome: 'Ana'),
      item(alunoId: 1, nome: 'Ana'),
      item(alunoId: 2, nome: 'Beto'),
    ]);
    expect(grupos.map((g) => g.alunoNome), ['Ana', 'Beto']);
    expect(checkinDoAlunoLinha(grupos.first), '2 treinos · Full');
    expect(checkinDoAlunoLinha(grupos.last), 'Full');
  });
}
