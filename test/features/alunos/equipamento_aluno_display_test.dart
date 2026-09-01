import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/equipamento_aluno_display.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';

void main() {
  test('equipamentoChoiceValue', () {
    expect(equipamentoChoiceValue(true), 'Sim');
    expect(equipamentoChoiceValue(false), 'Não');
  });

  test('equipamentosCountLabel', () {
    expect(equipamentosCountLabel(0), 'Sem restrição');
    expect(equipamentosCountLabel(1), '1 equipamento');
    expect(equipamentosCountLabel(3), '3 equipamentos');
  });

  test('equipamentoFxIcon cobre o enum', () {
    for (final item in Equipamento.values) {
      expect(equipamentoFxIcon(item), isNotEmpty);
    }
  });
}
