import '../../../core/utils/fx_utils.dart';
import '../data/evolucao_repository.dart';

enum EvolucaoHubView { medidas, recordes }

String evolucaoHubViewLabel(EvolucaoHubView view) => switch (view) {
  EvolucaoHubView.medidas => 'Medidas',
  EvolucaoHubView.recordes => 'Recordes',
};

const evolucaoDetalheSecoes = [
  (value: 'medidas', label: 'Medidas'),
  (value: 'recordes', label: 'Recordes'),
];

EvolucaoHubView evolucaoHubViewFromSecao(String value) =>
    value == 'recordes' ? EvolucaoHubView.recordes : EvolucaoHubView.medidas;

String evolucaoCountLabel(int count, {required bool recordes}) {
  if (recordes) {
    if (count <= 0) return '0';
    return '$count';
  }
  if (count <= 0) return '0';
  return '$count';
}

String evolucaoMedidasHint(int count) {
  if (count <= 0) return 'Nenhuma medida ainda';
  if (count == 1) return '1 registro';
  return '$count registros';
}

String evolucaoRecordesHint(int count) {
  if (count <= 0) return 'Nenhuma marca ainda';
  if (count == 1) return '1 marca pessoal';
  return '$count marcas pessoais';
}

String evolucaoHubSubtitle({
  required EvolucaoHubView view,
  String? variacao,
}) {
  final label = evolucaoHubViewLabel(view);
  final stamp = variacao?.trim();
  if (stamp == null || stamp.isEmpty) return label;
  return '$label · $stamp';
}

String evolucaoPesoAtual(List<MedidaCorporal> medidas) {
  final comPeso = [...medidas.where((m) => m.peso != null)]
    ..sort((a, b) => a.data.compareTo(b.data));
  if (comPeso.isEmpty) return '—';
  return '${comPeso.last.peso!.toStringAsFixed(1)} kg';
}

String evolucaoVariacaoPeso(List<MedidaCorporal> medidas) {
  final comPeso = medidas.where((m) => m.peso != null).toList();
  if (comPeso.length < 2) return '';
  comPeso.sort((a, b) => a.data.compareTo(b.data));
  final primeiro = comPeso.first.peso!;
  final ultimo = comPeso.last.peso!;
  final diff = ultimo - primeiro;
  final sinal = diff >= 0 ? '+' : '';
  return '$sinal${diff.toStringAsFixed(1)} kg desde o início';
}

String evolucaoMedidaLabel(MedidaCorporal medida) {
  try {
    return fxDateShort(DateTime.parse(medida.data));
  } catch (_) {
    return medida.data;
  }
}

String evolucaoMedidaSubtitle(MedidaCorporal medida) {
  final parts = <String>[];
  if (medida.peso != null) {
    parts.add('${medida.peso!.toStringAsFixed(1)} kg');
  }
  if (medida.cintura != null) {
    parts.add('Abdômen ${medida.cintura!.toStringAsFixed(1)} cm');
  }
  if (medida.quadril != null) {
    parts.add('Quadril ${medida.quadril!.toStringAsFixed(1)} cm');
  }
  if (medida.braco != null) {
    parts.add('Braço ${medida.braco!.toStringAsFixed(1)} cm');
  }
  return parts.isEmpty ? 'Sem medidas' : parts.join(' · ');
}

String evolucaoMedidaValue(MedidaCorporal medida) {
  if (medida.peso != null) {
    return '${medida.peso!.toStringAsFixed(1)} kg';
  }
  if (medida.cintura != null) {
    return '${medida.cintura!.toStringAsFixed(1)} cm';
  }
  return '';
}

String evolucaoRecordeSubtitle(RecordePessoal recorde) {
  final parts = <String>[];
  if (recorde.cargaKg != null) {
    parts.add('${recorde.cargaKg!.toStringAsFixed(1)} kg');
  }
  if (recorde.repeticoes != null) {
    parts.add('${recorde.repeticoes} reps');
  }
  try {
    parts.add(fxDateShort(DateTime.parse(recorde.data)));
  } catch (_) {
    parts.add(recorde.data);
  }
  return parts.join(' · ');
}

String evolucaoRecordeValue(RecordePessoal recorde) {
  if (recorde.cargaKg != null) {
    return '${recorde.cargaKg!.toStringAsFixed(1)} kg';
  }
  if (recorde.repeticoes != null) return '${recorde.repeticoes} reps';
  return '';
}

List<double> evolucaoPesosOrdenados(List<MedidaCorporal> medidas) {
  final pesos = [...medidas]..sort((a, b) => a.data.compareTo(b.data));
  return pesos.where((m) => m.peso != null).map((m) => m.peso!).toList();
}
