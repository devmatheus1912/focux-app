import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/widgets/treino_salvo_picker_sheet.dart';

Treino _treino(int id, {bool template = false}) =>
    Treino(id: id, nome: 'Plano $id', isTemplate: template, exercicios: const []);

void main() {
  test('planos salvos: templates primeiro e sem os já vinculados', () {
    final planos = planosSalvosParaEscolha(
      [_treino(1), _treino(2, template: true), _treino(3), _treino(4, template: true)],
      excluirIds: {3, 4},
    );

    expect(planos.map((t) => t.id), [2, 1]);
  });
}
