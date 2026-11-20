import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/models/exercicios_ui_filter.dart';

void main() {
  test('filtro ativo: busca, grupo ou equipamento', () {
    expect(const ExerciciosUiFilter().hasActive, isFalse);
    expect(const ExerciciosUiFilter(query: '  ').hasActive, isFalse);
    expect(const ExerciciosUiFilter(query: 'supino').hasActive, isTrue);
    expect(
      const ExerciciosUiFilter(grupo: GrupoMuscular.peito).hasActive,
      isTrue,
    );
    expect(
      const ExerciciosUiFilter(equipamento: Equipamento.halter).hasActive,
      isTrue,
    );
  });

  test('copyWith limpa grupo e equipamento sem perder a busca', () {
    const f = ExerciciosUiFilter(
      query: 'remada',
      grupo: GrupoMuscular.costasLatissimo,
      equipamento: Equipamento.barra,
    );
    final limpo = f.copyWith(clearGrupo: true, clearEquipamento: true);
    expect(limpo.query, 'remada');
    expect(limpo.grupo, isNull);
    expect(limpo.equipamento, isNull);
  });
}
