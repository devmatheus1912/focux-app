import '../../exercicios/data/enums.dart';

String equipamentoChoiceValue(bool on) => on ? 'Sim' : 'Não';

String equipamentoFxIcon(Equipamento equipamento) {
  return switch (equipamento) {
    Equipamento.barra ||
    Equipamento.halter ||
    Equipamento.kettlebell ||
    Equipamento.smith => 'dumbbell',
    Equipamento.maquina || Equipamento.polia => 'target',
    Equipamento.pesoCorporal => 'users',
    Equipamento.banda || Equipamento.trx || Equipamento.bolaSuica => 'spark',
    Equipamento.banco || Equipamento.caixa => 'home',
    Equipamento.corda => 'flame',
    Equipamento.outros => 'plus',
  };
}

String equipamentosCountLabel(int count) {
  if (count <= 0) return 'Sem restrição';
  if (count == 1) return '1 equipamento';
  return '$count equipamentos';
}

String equipamentosSaveSuccess() => 'Equipamentos atualizados.';
