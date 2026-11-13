import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_display.dart';

void main() {

  test('KPI de medidas conta só registros com conteúdo', () {
    final lista = [
      MedidaCorporal(id: 1, data: '2026-09-01', peso: 60),
      MedidaCorporal(id: 2, data: '2026-09-02'),
      MedidaCorporal(id: 3, data: '2026-09-03', cintura: 70),
    ];
    expect(lista.where(evolucaoMedidaTemConteudo), hasLength(2));
    expect(
      evolucaoMedidaSubtitle(MedidaCorporal(id: 1, data: '2026-09-01', peso: 60)),
      '60,0 kg',
    );
    expect(
      evolucaoMedidaSubtitle(MedidaCorporal(id: 9, data: '2026-09-01')),
      'Registro sem valores',
    );
  });

  test('histórico junta gordura e massa da mesma data e guarda a avaliação', () {
    final registros = registrosDoHistorico(
      [
        MedidaCorporal(id: 2, data: '2026-11-04', peso: 110),
        MedidaCorporal(id: 1, data: '2026-10-30', peso: 90),
      ],
      gordura: [(data: '2026-10-30', valor: 20, avaliacaoId: 5, conferido: false)],
      massa: [
        (data: '2026-10-30', valor: 10, avaliacaoId: 5, conferido: false),
        (data: '2026-11-06', valor: 80, avaliacaoId: 6, conferido: false),
      ],
    );
    expect(registros.map((r) => r.data), ['2026-11-06', '2026-11-04', '2026-10-30']);
    expect(registros.first.medida, isNull);
    expect(evolucaoRegistroSubtitle(registros.last), '90,0\u00A0kg · Gordura 20,0% · Massa magra 10,0%');
    expect(registros.last.massa?.avaliacaoId, 5);
  });

  test('autor só aparece quando foi o aluno', () {
    expect(evolucaoAutorLabel('PERSONAL'), isNull);
    expect(evolucaoAutorLabel('ALUNO'), isNotNull);
  });
}
