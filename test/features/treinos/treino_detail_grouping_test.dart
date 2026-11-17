import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/metodo_exercicio.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/utils/treino_detail_grouping.dart';

TreinoExercicioItem _item({
  required int id,
  required String nome,
  GrupoMuscular? grupo,
  String? musculo,
  int ordem = 0,
}) {
  return TreinoExercicioItem(
    id: id,
    exercicio: Exercicio(
      id: id,
      nome: nome,
      musculoAlvo: musculo,
      grupoMuscularPrimario: grupo,
    ),
    series: 3,
    repeticoes: '10',
    ordem: ordem,
  );
}

void main() {
  test('displayWorkoutName corrige Forca no detalhe', () {
    expect(displayWorkoutName('Treino Forca'), 'Treino Força');
  });

  test('context label prefers aluno, then template, then plano', () {
    final template = Treino(
      id: 1,
      nome: 'Forca',
      isTemplate: true,
      exercicios: const [],
    );
    final plano = Treino(id: 2, nome: 'A', exercicios: const []);
    expect(treinoDetailContextLabel(template, '  Ana  '), 'Ana');
    expect(treinoDetailContextLabel(template, null), 'Template base');
    expect(treinoDetailContextLabel(plano, ' '), 'Plano base');
  });

  test('load formatting stays honest', () {
    expect(formatTreinoLoadKg(null), '—');
    expect(formatTreinoLoadKg(0), '—');
    expect(formatTreinoLoadKg(30), '30kg');
    expect(formatTreinoLoadKg(12.5), '12,5kg');
  });


  test('falls back to musculo alvo then OUTROS', () {
    expect(
      treinoDetailGroupLabel(_item(id: 1, nome: 'X', musculo: 'Core')),
      'CORE',
    );
    expect(treinoDetailGroupLabel(_item(id: 2, nome: 'Y')), 'OUTROS');
  });



  test('exercise line keeps prescription scannable without empty load', () {
    expect(
      treinoDetailExerciseLine(
        _item(id: 1, nome: 'Supino', grupo: GrupoMuscular.peito),
      ),
      '3 × 10 · 60 s',
    );
    expect(
      treinoDetailExerciseLine(
        TreinoExercicioItem(
          id: 2,
          exercicio: Exercicio(id: 2, nome: 'Remada'),
          series: 4,
          repeticoes: '8-10',
          cargaKg: 40,
          descansoSegundos: 90,
          ordem: 1,
          tipoSerie: 'SUPERSET',
          grupoSuperset: 1,
        ),
      ),
      '4 × 8-10 · 40kg · 90 s · SS1',
    );
    expect(
      treinoDetailExerciseLine(
        TreinoExercicioItem(
          id: 3,
          exercicio: Exercicio(id: 3, nome: 'Rosca'),
          series: 3,
          repeticoes: '12',
          descansoSegundos: 45,
          ordem: 2,
          tipoSerie: 'DROPSET',
          metodo: const MetodoExercicio(tecnica: Tecnica.dropset),
        ),
      ),
      '3 × 12 · 45 s · Drop-set',
    );
  });
}
