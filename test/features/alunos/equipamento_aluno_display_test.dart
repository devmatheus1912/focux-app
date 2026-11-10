import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/equipamento_aluno_display.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';

void main() {
  test('equipamentosMarcadosLabel', () {
    expect(equipamentosMarcadosLabel(0), 'Marcados · nenhum');
    expect(equipamentosMarcadosLabel(1), 'Marcados · 1 equipamento');
    expect(equipamentosMarcadosLabel(3), 'Marcados · 3 equipamentos');
  });

  test('atalho só fica marcado com a seleção exata dele', () {
    final basica = equipamentosAtalhos.first;
    expect(equipamentosAtalhoDaSelecao({...basica.equipamentos}), basica);
    expect(
      equipamentosAtalhoDaSelecao({...basica.equipamentos, Equipamento.trx}),
      isNull,
    );
    expect(
      equipamentosAtalhoDaSelecao({Equipamento.pesoCorporal})?.rotulo,
      'Só peso do corpo',
    );
    expect(equipamentosAtalhoDaSelecao({}), isNull);
  });

  test('nenhum atalho repete a lista de outro', () {
    final listas = equipamentosAtalhos.map((a) => a.equipamentos).toList();
    for (var i = 0; i < listas.length; i++) {
      for (var j = i + 1; j < listas.length; j++) {
        expect(
          listas[i].length == listas[j].length &&
              listas[i].containsAll(listas[j]),
          isFalse,
        );
      }
    }
  });
}
