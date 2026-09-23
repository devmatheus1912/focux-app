import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/historico_sessao_metrics.dart';

void main() {
  test('volume e sparkline da sessão', () {
    final series = [
      const ExecucaoSerie(id: 1, numero: 1, cargaKg: 40, repeticoes: '10'),
      const ExecucaoSerie(id: 2, numero: 2, cargaKg: 45, repeticoes: '8'),
    ];
    expect(historicoVolumeExercicio(series), 40 * 10 + 45 * 8);
    expect(historicoVolumeLabel(6800), '6.8 mil kg');
    expect(historicoVolumeLabel(90), '90 kg');
    expect(
      historicoCargaDeltaLabel(cargaAtual: 50, cargaAnterior: 40),
      '+10 kg vs anterior',
    );
    expect(historicoCargaSparkValues(series), [40.0, 45.0]);
    expect(historicoSinalChipLabel('MELHOROU'), 'Melhorou');
  });

  test('métricas locais a partir da execução', () {
    final exec = ExecucaoTreino(
      id: 9,
      treinoId: 1,
      treinoNome: 'Costa',
      status: 'CONCLUIDO',
      exercicios: [
        ExecucaoExercicio(
          id: 1,
          treinoExercicioId: 1,
          exercicioNome: 'Puxada',
          series: 4,
          seriesFeitas: 4,
          concluido: true,
          seriesDetalhes: const [
            ExecucaoSerie(id: 1, numero: 1, cargaKg: 40, repeticoes: '10'),
            ExecucaoSerie(id: 2, numero: 2, cargaKg: 40, repeticoes: '10'),
          ],
        ),
      ],
    );
    final m = historicoSessaoMetricsFromExecucao(exec);
    expect(m.seriesFeitas, 4);
    expect(m.seriesPlanejadas, 4);
    expect(m.volumeKg, 800);
    expect(m.volumeLabel, '800 kg');
  });

  test('volume some quando a sessão não tem séries', () {
    final exec = ExecucaoTreino(
      id: 10,
      treinoId: 1,
      treinoNome: 'Full',
      status: 'CONCLUIDO',
      exercicios: [
        ExecucaoExercicio(
          id: 1,
          treinoExercicioId: 1,
          exercicioNome: 'Supino',
          series: 4,
          seriesFeitas: 0,
          concluido: true,
        ),
      ],
    );
    final m = historicoSessaoMetricsFromExecucao(exec);
    expect(m.seriesFeitas, 0);
    expect(m.volumeLabel, '—');
  });

  test('dto BFF mapeia sinal', () {
    final m = historicoSessaoMetricsFromDto(
      const SessaoEvolucaoDto(
        seriesFeitas: 28,
        seriesPlanejadas: 28,
        recordes: 1,
        sinal: 'MELHOROU',
        sinalLabel: 'Volume acima da sessão anterior',
        volumeKg: 6800,
        volumeAnteriorKg: 5200,
      ),
    );
    expect(m.sinal, 'MELHOROU');
    expect(m.volumeAnteriorKg, 5200);
  });

  test('volume hint some comparação quando a sessão não tem carga', () {
    expect(
      historicoVolumeHint(volumeKg: null, volumeAnteriorKg: 1400),
      'sem cargas',
    );
    expect(
      historicoVolumeHint(volumeKg: 1800, volumeAnteriorKg: 1400),
      'antes 1.4 mil kg',
    );
    expect(
      historicoVolumeHint(volumeKg: 800, volumeAnteriorKg: null),
      'nesta sessão',
    );
  });
}
