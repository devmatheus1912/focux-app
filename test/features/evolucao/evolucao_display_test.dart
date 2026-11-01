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
      '60,0 kg',
    );
    expect(
      evolucaoMedidaSubtitle(MedidaCorporal(id: 9, data: '2026-09-01')),
      'Registro sem valores',
    );
  });
}
