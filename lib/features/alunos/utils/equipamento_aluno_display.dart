import '../../exercicios/data/enums.dart';

/// Resumo do título da lista: "Marcados · 3 equipamentos".
String equipamentosMarcadosLabel(int count) {
  if (count <= 0) return 'Marcados · nenhum';
  if (count == 1) return 'Marcados · 1 equipamento';
  return 'Marcados · $count equipamentos';
}

String equipamentosSaveSuccess() => 'Equipamentos atualizados.';

/// Atalho de espaço: um toque preenche a lista e o personal ajusta depois.
/// Só no app; nada de espaço é gravado no servidor.
class EquipamentosAtalho {
  const EquipamentosAtalho(this.rotulo, this.equipamentos);

  final String rotulo;
  final Set<Equipamento> equipamentos;
}

const equipamentosAtalhos = [
  EquipamentosAtalho('Academia básica', {
    Equipamento.barra,
    Equipamento.halter,
    Equipamento.maquina,
    Equipamento.polia,
    Equipamento.banco,
    Equipamento.pesoCorporal,
  }),
  EquipamentosAtalho('Casa com equipamento', {
    Equipamento.halter,
    Equipamento.kettlebell,
    Equipamento.banda,
    Equipamento.banco,
    Equipamento.pesoCorporal,
    Equipamento.bolaSuica,
    Equipamento.corda,
    Equipamento.trx,
  }),
  EquipamentosAtalho('Só peso do corpo', {Equipamento.pesoCorporal}),
  EquipamentosAtalho('Ao ar livre', {
    Equipamento.pesoCorporal,
    Equipamento.banda,
    Equipamento.corda,
    Equipamento.trx,
  }),
];

/// O atalho cuja lista é exatamente a seleção (o chip fica marcado só aí).
EquipamentosAtalho? equipamentosAtalhoDaSelecao(Set<Equipamento> selecao) {
  for (final a in equipamentosAtalhos) {
    if (a.equipamentos.length == selecao.length &&
        a.equipamentos.containsAll(selecao)) {
      return a;
    }
  }
  return null;
}
