import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/relatorio/utils/relatorio_aluno_display.dart';

void main() {
  test('relatorioAlunoPeriodoValueLabel cobre preset e mês cheio', () {
    expect(
      relatorioAlunoPeriodoValueLabel(dias: 30),
      '30 dias',
    );
    expect(
      relatorioAlunoPeriodoValueLabel(
        dias: 31,
        inicio: DateTime(2026, 8, 1),
        fim: DateTime(2026, 8, 31),
      ),
      'Agosto 2026',
    );
  });

  test('relatorioAlunoPeriodoOpcoes mistura presets e 6 meses', () {
    final agora = DateTime(2026, 9, 7);
    final opcoes = relatorioAlunoPeriodoOpcoes(agora: agora);
    expect(opcoes.map((o) => o.key).toList(), [
      '7',
      '30',
      '90',
      '180',
      'm:2026-09',
      'm:2026-08',
      'm:2026-07',
      'm:2026-06',
      'm:2026-05',
      'm:2026-04',
    ]);
    expect(opcoes.firstWhere((o) => o.key == 'm:2026-08').label, 'Agosto 2026');
    expect(opcoes.any((o) => o.key == 'custom'), isFalse);
  });



  test('relatorioAlunoDeltaLabel e check-ins', () {
    expect(relatorioAlunoDeltaLabel(10), '+10,0%');
    expect(relatorioAlunoDeltaLabel(-2.5), '-2,5%');
    expect(relatorioAlunoCheckinsLabel(0), 'Nenhum');
    expect(relatorioAlunoCheckinsLabel(1), '1 check-in');
    expect(relatorioAlunoCheckinsLabel(8), '8 check-ins');
  });

}
