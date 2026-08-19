import 'package:flutter_test/flutter_test.dart';
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
    expect(formatTreinoLoadKg(12.5), '12.5kg');
  });

  test('groups by muscle and numbers locally', () {
    final items = [
      _item(id: 1, nome: 'Supino', grupo: GrupoMuscular.peito, ordem: 0),
      _item(id: 2, nome: 'Crucifixo', grupo: GrupoMuscular.peito, ordem: 1),
      _item(
        id: 3,
        nome: 'Remada',
        grupo: GrupoMuscular.costasLatissimo,
        ordem: 2,
      ),
    ];

    expect(treinoDetailGroupLabel(items[0]), 'PEITO');
    expect(treinoDetailShowsGroupHeader(items, 0), isTrue);
    expect(treinoDetailShowsGroupHeader(items, 1), isFalse);
    expect(treinoDetailShowsGroupHeader(items, 2), isTrue);
    expect(treinoDetailLocalIndexInGroup(items, 1), 2);
    expect(treinoDetailGroupExerciseCount(items, 0), 2);
    expect(treinoDetailIsLastInGroup(items, 1), isTrue);
    expect(treinoDetailIsLastInGroup(items, 2), isTrue);
  });

  test('falls back to musculo alvo then OUTROS', () {
    expect(
      treinoDetailGroupLabel(_item(id: 1, nome: 'X', musculo: 'Core')),
      'CORE',
    );
    expect(treinoDetailGroupLabel(_item(id: 2, nome: 'Y')), 'OUTROS');
  });
}
