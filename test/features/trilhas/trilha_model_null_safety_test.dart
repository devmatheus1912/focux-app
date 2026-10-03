import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/trilhas/models/trilha.dart';

void main() {
  test('TrilhaModel.fromJson aceita campos nulos', () {
    final trilha = TrilhaModel.fromJson({
      'id': null,
      'alunoId': null,
      'titulo': null,
      'metaValor': null,
      'valorAtual': null,
      'marcos': [
        {'id': null, 'titulo': 'Primeiro marco', 'ordem': null},
      ],
    });
    expect(trilha.id, 0);
    expect(trilha.alunoId, 0);
    expect(trilha.titulo, '');
    expect(trilha.metaTipo, 'TREINOS');
    expect(trilha.metaValor, isNull);
    expect(trilha.valorAtual, 0);
    expect(trilha.marcos.single.id, 0);
    expect(trilha.marcos.single.titulo, 'Primeiro marco');
  });
}
