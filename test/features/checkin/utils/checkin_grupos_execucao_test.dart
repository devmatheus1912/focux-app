import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/features/checkin/models/treino_previa.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_textos.dart';
import 'package:focux_app/features/checkin/utils/serie_de_agora.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_input.dart';
import 'package:focux_app/features/checkin/utils/treino_previa_view.dart';
import 'package:focux_app/features/treinos/utils/grupos_de_serie.dart';
import 'package:focux_app/features/treinos/utils/prescricao_serie.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

/// Grupos de série na execução e na prévia (SPEC-grupos-na-execucao).
void main() {
  final s = SPt();

  // 2 aquecimentos (12 reps), 3 válidas (8-12, 40 kg), 2 back-off.
  final linhas = desagruparSeries(const [
    GrupoDeSeries(papel: PapelDaSerie.aquecimento, series: 2, repeticoes: '12', descansoSegundos: 45),
    GrupoDeSeries(papel: PapelDaSerie.valida, series: 3, repeticoes: '8-12', cargaKg: 40, descansoSegundos: 90),
    GrupoDeSeries(papel: PapelDaSerie.backoff, series: 2, repeticoes: '8-12', cargaKg: 32, descansoSegundos: 90),
  ]);

  ExecucaoExercicio ee({
    int feitas = 0,
    List<ExecucaoSerie> anteriores = const [],
    String nome = 'Desenvolvimento',
  }) => ExecucaoExercicio.fromJson({
    'id': 1,
    'treinoExercicioId': 2,
    'exercicioNome': nome,
    'series': 7,
    'repeticoes': '8-12',
    'seriesFeitas': feitas,
    'concluido': false,
    'proximaRepeticoes': linhas[feitas].repeticoes,
    'seriesPrescritas': [for (final l in linhas) l.toJson()],
    'seriesAnteriores': [for (final a in anteriores) a.toJson()],
  });

  test('posição no grupo: aquecimento 1 de 2, válida 2 de 3, back-off 1 de 2', () {
    String rotulo(int n) => serieDeAgora(ee(), numero: n).rotulo;
    expect(rotulo(1), 'Aquecimento 1 de 2');
    expect(rotulo(4), 'Válida 2 de 3');
    expect(rotulo(6), 'Back-off 1 de 2');
    // Só válidas: sem grupos, vale "Série n de m".
    final soValidas = ExecucaoExercicio.fromJson({
      'id': 1,
      'treinoExercicioId': 2,
      'exercicioNome': 'Supino',
      'series': 1,
      'seriesFeitas': 0,
      'concluido': false,
      'seriesPrescritas': [const SeriePrescrita(numero: 1, repeticoes: '10').toJson()],
    });
    expect(serieDeAgora(soValidas).rotulo, 'Série 1 de 1');
  });

  test('"Depois": a próxima série do grupo; outro exercício com o mesmo nome ganha "(2ª vez)"', () {
    expect(checkinTextoDepois(s, ee(feitas: 1), 'Supino'), 'Depois: Válida 1 · 8-12 reps · 40 kg');
    final semGrupos = ExecucaoExercicio.fromJson({
      'id': 1,
      'treinoExercicioId': 2,
      'exercicioNome': 'Desenvolvimento',
      'series': 3,
      'seriesFeitas': 2,
      'concluido': false,
    });
    expect(
      checkinTextoDepois(s, semGrupos, 'Desenvolvimento'),
      'Depois: Desenvolvimento (2ª vez)',
    );
  });

  test('valor inicial: aquecimento não herda carga de válida quando o desenho mudou', () {
    // Última sessão sem grupos: 3 séries de 40 kg x 10.
    final antes = [
      for (var n = 1; n <= 3; n++)
        ExecucaoSerie(id: n, numero: n, cargaKg: 40, repeticoes: '10'),
    ];
    final seed = checkinCurrentSetSeed(ee: ee(anteriores: antes), numero: 1);
    expect(seed.reps, 12);
    expect(seed.cargaKg, isNull);
  });

  // A meta manda: válida com carga prescrita usa a meta mesmo com o mesmo
  // desenho; o "Última vez" fica no chip, a um toque.
  test('valor inicial: válida com carga prescrita usa a meta, não a sessão passada', () {
    final antes = [
      for (var n = 1; n <= 7; n++)
        ExecucaoSerie(id: n, numero: n, cargaKg: n <= 2 ? 20 : 42.5, repeticoes: n <= 2 ? '12' : '9'),
    ];
    final seed = checkinCurrentSetSeed(ee: ee(feitas: 2, anteriores: antes), numero: 3);
    expect(seed.cargaKg, 40);
    expect(seed.reps, 8);
  });

  test('prévia mostra o resumo dos grupos, sem descanso', () {
    final e = TreinoPreviaExercicio(
      treinoExercicioId: 2,
      exercicioNome: 'Desenvolvimento',
      series: 7,
      repeticoes: '8-12',
      descansoSegundos: 90,
      seriesPrescritas: linhas,
    );
    expect(treinoPreviaPrescricao(s, e), '2 aquec. · 3 × 8-12 · 2 back-off');
  });
}
