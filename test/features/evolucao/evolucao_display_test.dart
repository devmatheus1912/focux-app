import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_display.dart';

void main() {
  test('evolucaoHubViewLabel e subtitle', () {
    expect(
      evolucaoUltimaMedidaHint([
        MedidaCorporal(id: 1, data: '2026-01-01', peso: 80),
        MedidaCorporal(id: 2, data: '2026-03-01', peso: 78),
      ]),
      'Última em 01/03',
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
      '-2,0 kg desde o início',
    );
  });

  test('evolucaoPesoAtual usa a última medida com peso', () {
    expect(evolucaoPesoAtual(const []), '—');
    expect(
      evolucaoPesoAtual([
        MedidaCorporal(id: 1, data: '2026-01-01', peso: 80),
        MedidaCorporal(id: 2, data: '2026-03-01', peso: 78.5),
      ]),
      '78,5 kg',
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
    expect(evolucaoMedidaSubtitle(medida), '78,5 kg · Abdômen 82,0 cm');
    final recorde = RecordePessoal(
      id: 1,
      exercicioId: 9,
      exercicioNome: 'Supino',
      data: '2026-09-01',
      cargaKg: 80,
      repeticoes: 5,
    );
    expect(evolucaoRecordeSubtitle(recorde), '80,0 kg · 5 reps · 01/09');
    expect(evolucaoRecordeValue(recorde), '80,0 kg');
    expect(evolucaoHubViewFromSecao('recordes'), EvolucaoHubView.recordes);
    expect(evolucaoDetalheSecoes, hasLength(2));
  });

  test('KPI de medidas conta só registros com conteúdo', () {
    final lista = [
      MedidaCorporal(id: 1, data: '2026-09-01', peso: 60),
      MedidaCorporal(id: 2, data: '2026-09-02'),
      MedidaCorporal(id: 3, data: '2026-09-03', cintura: 70),
    ];
    expect(evolucaoMedidasComConteudo(lista), hasLength(2));
    expect(
      evolucaoMedidaSubtitle(MedidaCorporal(id: 1, data: '2026-09-01', peso: 60)),
      '60,0 kg',
    );
    expect(
      evolucaoMedidaSubtitle(MedidaCorporal(id: 9, data: '2026-09-01')),
      'Registro sem valores',
    );
    expect(evolucaoPesosOrdenados(lista), [60.0]);
  });

  test('recordes ficam com a maior carga de cada exercício', () {
    RecordePessoal r(int id, String nome, double carga) => RecordePessoal(
      id: id,
      exercicioId: id,
      exercicioNome: nome,
      data: '2026-10-30',
      cargaKg: carga,
    );
    final melhores = evolucaoMelhoresRecordes([
      r(1, 'Supino', 60),
      r(2, 'supino', 80),
      r(3, 'Agachamento', 100),
    ]);
    expect(melhores.map((m) => m.cargaKg), [100, 80]);
  });
}
