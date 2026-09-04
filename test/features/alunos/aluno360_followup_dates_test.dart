import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_followup_dates.dart';

void main() {
  test('horizontes de follow-up são datas relativas ao dia', () {
    final ops = alunoFollowUpDateOptions(DateTime(2026, 9, 4, 18, 30));
    expect(ops.map((o) => o.days).toList(), alunoFollowUpDateHorizons);
    expect(ops.first.label, 'Hoje');
    expect(ops.first.subtitle, '04/09/2026');
    expect(ops.first.date, DateTime(2026, 9, 4));
    expect(ops[1].label, 'Amanhã');
    expect(ops[1].date, DateTime(2026, 9, 5));
    expect(ops.last.label, 'Em 30 dias');
    expect(ops.last.date, DateTime(2026, 10, 4));
    expect(
      alunoFollowUpDateSelected(options: ops, current: DateTime(2026, 9, 11)),
      DateTime(2026, 9, 11),
    );
    expect(
      alunoFollowUpDateSelected(options: ops, current: DateTime(2026, 12, 1)),
      isNull,
    );
  });
}
