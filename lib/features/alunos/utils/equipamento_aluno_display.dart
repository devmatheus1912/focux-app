import 'package:flutter/widgets.dart';
import '../../exercicios/data/enums.dart';
import '../../../core/theme/fx_icons.dart';

IconData equipamentoFxIcon(Equipamento equipamento) {
  return switch (equipamento) {
    Equipamento.barra ||
    Equipamento.halter ||
    Equipamento.kettlebell ||
    Equipamento.smith => FxIcons.treino,
    Equipamento.maquina || Equipamento.polia => FxIcons.alvo,
    Equipamento.pesoCorporal => FxIcons.grupo,
    Equipamento.banda || Equipamento.trx || Equipamento.bolaSuica => FxIcons.ia,
    Equipamento.banco || Equipamento.caixa => FxIcons.inicio,
    Equipamento.corda => FxIcons.fogo,
    Equipamento.outros => FxIcons.adicionar,
  };
}

String equipamentosCountLabel(int count) {
  if (count <= 0) return 'Sem restrição';
  if (count == 1) return '1 equipamento';
  return '$count equipamentos';
}

String equipamentosSaveSuccess() => 'Equipamentos atualizados.';
