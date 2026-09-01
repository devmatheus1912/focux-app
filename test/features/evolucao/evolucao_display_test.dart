import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_display.dart';

void main() {
  test('evolucaoHubViewLabel e subtitle', () {
    expect(evolucaoHubViewLabel(EvolucaoHubView.medidas), 'Medidas');
    expect(evolucaoHubViewLabel(EvolucaoHubView.recordes), 'Recordes');
    expect(
      evolucaoHubSubtitle(view: EvolucaoHubView.medidas, variacao: null),
      'Medidas',
    );
    expect(
      evolucaoHubSubtitle(
        view: EvolucaoHubView.medidas,
        variacao: '-2.0 kg desde o início',
      ),
      'Medidas · -2.0 kg desde o início',
    );
  });

  test('evolucaoVariacaoPeso precisa de dois pesos', () {
    expect(evolucaoVariacaoPeso(const []), '');
    expect(
      evolucaoVariacaoPeso([
        MedidaCorporal(id: 1, data: '2026-01-01', peso: 80),
      ]),
      '',
    );
    expect(
      evolucaoVariacaoPeso([
        MedidaCorporal(id: 1, data: '2026-01-01', peso: 80),
        MedidaCorporal(id: 2, data: '2026-03-01', peso: 78),
      ]),
      '-2.0 kg desde o início',
    );
  });

  test('evolucaoMedida e recorde labels', () {
    final medida = MedidaCorporal(
      id: 1,
      data: '2026-09-01',
      peso: 78.5,
      cintura: 82,
    );
    expect(evolucaoMedidaLabel(medida), '01/09');
    expect(evolucaoMedidaSubtitle(medida), '78.5 kg · Abdômen 82.0 cm');
    expect(evolucaoMedidaValue(medida), '78.5 kg');
    final recorde = RecordePessoal(
      id: 1,
      exercicioId: 9,
      exercicioNome: 'Supino',
      data: '2026-09-01',
      cargaKg: 80,
      repeticoes: 5,
    );
    expect(evolucaoRecordeSubtitle(recorde), '80.0 kg · 5 reps · 01/09');
    expect(evolucaoRecordeValue(recorde), '80.0 kg');
  });
}
