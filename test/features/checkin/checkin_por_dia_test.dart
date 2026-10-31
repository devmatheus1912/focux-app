import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_personal_home.dart';
import 'package:focux_app/features/checkin/utils/checkin_personal_display.dart';

CheckinPersonalItem _item(int id, int aluno, DateTime? quando, {bool parcial = false}) =>
    CheckinPersonalItem(
      id: id,
      alunoId: aluno,
      alunoNome: 'Aluno $aluno',
      treinoNome: 'A',
      iniciadoEm: quando,
      parcial: parcial,
    );

void main() {
  test('semana agrupa por dia, do mais recente', () {
    final dias = checkinPorDia([
      _item(1, 1, DateTime(2026, 9, 8, 10)),
      _item(2, 1, DateTime(2026, 9, 9, 10)),
      _item(3, 2, DateTime(2026, 9, 9, 11)),
    ], now: DateTime(2026, 9, 10, 18));
    expect(dias.map((d) => d.$1), ['Ontem', '08/09']);
    expect(dias.first.$2, hasLength(2));
  });

  test('linha mostra parcial', () {
    final grupo =
        checkinPorAluno([_item(1, 1, DateTime(2026, 9, 9), parcial: true)]).first;
    expect(checkinDoAlunoLinha(grupo), 'A · parcial');
  });
}
