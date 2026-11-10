import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_followup_dates.dart';

void main() {
  test('data do contato sem o ano quando é o ano corrente', () {
    final agora = DateTime(2026, 9, 4, 18, 30);
    expect(alunoFollowUpDateLabel(DateTime(2026, 9, 11), agora: agora), '11/09');
    expect(
      alunoFollowUpDateLabel(DateTime(2027, 1, 2), agora: agora),
      '02/01/2027',
    );
  });
}
