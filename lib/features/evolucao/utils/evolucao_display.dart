import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/pt_br_display.dart';
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

/// Conta só registros com peso ou circunferência — alinha KPI e lista.
int evolucaoMedidasComConteudoCount(List<MedidaCorporal> medidas) =>
    medidas.where(evolucaoMedidaTemConteudo).length;

List<MedidaCorporal> evolucaoMedidasComConteudo(List<MedidaCorporal> medidas) {
  final ordenada = [...medidas.where(evolucaoMedidaTemConteudo)]
    ..sort((a, b) => b.data.compareTo(a.data));
  return ordenada;
}

String evolucaoRecordesHint(int count) {
  if (count <= 0) return 'Nenhuma marca ainda';
  if (count == 1) return '1 marca pessoal';
  return '$count marcas pessoais';
}

String evolucaoHubSubtitle() => 'Peso, medidas e recordes';

String evolucaoVariacaoValue(List<MedidaCorporal> medidas) {
  final stamp = evolucaoVariacaoPeso(medidas).trim();
  if (stamp.isEmpty) return '—';
  return stamp.replaceAll(' desde o início', '');
}

String evolucaoVariacaoHint(List<MedidaCorporal> medidas) {
  if (evolucaoVariacaoPeso(medidas).isEmpty) {
    return 'Registre duas medidas para ver o delta';
  }
  return 'Desde a 1ª medida';
}

String evolucaoUltimaMedidaHint(List<MedidaCorporal> medidas) {
  if (medidas.isEmpty) return 'Nenhuma medida ainda';
  final ordenada = [...medidas]..sort((a, b) => a.data.compareTo(b.data));
  try {
    return 'Última em ${fxDateShort(DateTime.parse(ordenada.last.data))}';
  } catch (_) {
    return 'Última em ${ordenada.last.data}';
  }
}

String evolucaoPesoAtual(List<MedidaCorporal> medidas) {
  final comPeso = [...medidas.where((m) => m.peso != null)]
    ..sort((a, b) => a.data.compareTo(b.data));
  if (comPeso.isEmpty) return '—';
  return formatBrKg(comPeso.last.peso!);
}

String evolucaoVariacaoPeso(List<MedidaCorporal> medidas) {
  final comPeso = medidas.where((m) => m.peso != null).toList();
  if (comPeso.length < 2) return '';
  comPeso.sort((a, b) => a.data.compareTo(b.data));
  final primeiro = comPeso.first.peso!;
  final ultimo = comPeso.last.peso!;
  final diff = ultimo - primeiro;
  final sinal = diff >= 0 ? '+' : '';
  return '$sinal${formatBrKg(diff)} desde o início';
}

String evolucaoMedidaLabel(MedidaCorporal medida) {
  try {
    return fxDateShort(DateTime.parse(medida.data));
  } catch (_) {
    return medida.data;
  }
}

bool evolucaoMedidaTemConteudo(MedidaCorporal medida) {
  return medida.peso != null ||
      medida.cintura != null ||
      medida.quadril != null ||
      medida.braco != null;
}

String evolucaoMedidaSubtitle(MedidaCorporal medida) {
  final parts = <String>[];
  if (medida.peso != null) {
    parts.add(formatBrKg(medida.peso!));
  }
  if (medida.cintura != null) {
    parts.add('Abdômen ${formatBrCm(medida.cintura!)}');
  }
  if (medida.quadril != null) {
    parts.add('Quadril ${formatBrCm(medida.quadril!)}');
  }
  if (medida.braco != null) {
    parts.add('Braço ${formatBrCm(medida.braco!)}');
  }
  if (parts.isNotEmpty) return parts.join(' · ');
  // Só chega aqui se a lista não filtrou por [evolucaoMedidaTemConteudo].
  return 'Registro sem valores';
}

String evolucaoMedidaValue(MedidaCorporal medida) {
  if (medida.peso != null) {
    return formatBrKg(medida.peso!);
  }
  if (medida.cintura != null) {
    return formatBrCm(medida.cintura!);
  }
  return '';
}

String evolucaoRecordeSubtitle(RecordePessoal recorde) {
  final parts = <String>[];
  if (recorde.cargaKg != null) {
    parts.add(formatBrKg(recorde.cargaKg!));
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
    return formatBrKg(recorde.cargaKg!);
  }
  if (recorde.repeticoes != null) return '${recorde.repeticoes} reps';
  return '';
}

List<double> evolucaoPesosOrdenados(List<MedidaCorporal> medidas) {
  final pesos = [...medidas]..sort((a, b) => a.data.compareTo(b.data));
  return pesos.where((m) => m.peso != null).map((m) => m.peso!).toList();
}
