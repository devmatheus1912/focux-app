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
        {'id': null, 'titulo': 'Primeira etapa', 'ordem': null, 'concluidoEm': null},
      ],
    });
    expect(trilha.id, 0);
    expect(trilha.titulo, '');
    expect(trilha.marcos.single.titulo, 'Primeira etapa');
    expect(trilha.marcos.single.concluidoEm, isNull);
  });

  test('nova trilha manda só nome, etapas, descrição e prazo', () {
    final json = NovaTrilhaRequest(
      alunoId: 3,
      titulo: 'Correr 5 km',
      marcos: const ['1 km', '3 km'],
      dataFim: DateTime(2026, 12, 1),
    ).toJson();
    expect(json.keys, containsAll(['alunoId', 'titulo', 'marcos', 'dataFim']));
    expect(json.containsKey('metaTipo'), isFalse);
    expect(json.containsKey('metaValor'), isFalse);
    expect(json['dataFim'], '2026-12-01');
  });
}
