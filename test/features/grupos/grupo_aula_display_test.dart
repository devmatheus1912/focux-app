import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/grupos/utils/grupo_aula_display.dart';

void main() {
  test('linha da aula: dia, horário e local', () {
    expect(
      grupoAulaLinha(
        inicio: DateTime(2026, 11, 12, 7),
        fim: DateTime(2026, 11, 12, 8),
        localAula: 'Studio',
      ),
      'qui. 12/11 · 07:00 – 08:00 · Studio',
    );
    expect(
      grupoAulaLinha(
        inicio: DateTime(2026, 11, 12, 7),
        fim: DateTime(2026, 11, 12, 8),
      ),
      'qui. 12/11 · 07:00 – 08:00',
    );
  });

  test('ocupação para o personal', () {
    expect(
      grupoAulaOcupacaoLabel(inscritos: 12, capacidadeMax: 20, status: 'ABERTA'),
      '12/20',
    );
    expect(
      grupoAulaOcupacaoLabel(inscritos: 20, capacidadeMax: 20, status: 'ABERTA'),
      'Lotada',
    );
    expect(
      grupoAulaOcupacaoLabel(inscritos: 3, capacidadeMax: 20, status: 'CANCELADA'),
      'Cancelada',
    );
  });

  test('dia por extenso curto e alunos escolhidos', () {
    expect(grupoAulaDiaLabel(DateTime(2026, 11, 12)), 'qui., 12/11');
    expect(grupoAulaAlunosEscolhidosLabel(0), 'Nenhum');
    expect(grupoAulaAlunosEscolhidosLabel(3), '3 alunos');
  });
}
