import 'plano_sucesso_model.dart';

String planoSucessoPercentLabel(int done, int total) {
  if (total <= 0) return '0%';
  return '${((done / total) * 100).round()}%';
}

String planoSucessoProgressHint(int done, int total) {
  if (total <= 0) return 'Sem etapas ainda';
  return '$done de $total etapas';
}

String planoSucessoRevisaoLabel(DateTime data) {
  final day = data.day.toString().padLeft(2, '0');
  final month = data.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String planoSucessoMetricHint({
  required int done,
  required int total,
  DateTime? proximaRevisao,
}) {
  final revisao =
      proximaRevisao == null
          ? 'sem revisão'
          : 'revisão ${planoSucessoRevisaoLabel(proximaRevisao)}';
  return '${planoSucessoProgressHint(done, total)} · $revisao';
}

String planoSucessoStatusLabel(String? status) {
  switch ((status ?? '').trim().toUpperCase()) {
    case 'ATIVO':
    case '':
      return 'Ativo';
    case 'PAUSADO':
      return 'Pausado';
    case 'CONCLUIDO':
      return 'Concluído';
    default:
      return status!.trim();
  }
}

String planoSucessoInicioHint(DateTime? data) {
  if (data == null) return 'Sem data de início';
  return 'Desde ${planoSucessoRevisaoLabel(data)}';
}

String planoSucessoMarcoSubtitle({
  required bool atingido,
  required bool atual,
  String? descricao,
  DateTime? dataAtingido,
}) {
  final desc = descricao?.trim();
  if (atingido) {
    final when =
        dataAtingido == null ? null : planoSucessoRevisaoLabel(dataAtingido);
    if (when != null && (desc == null || desc.isEmpty)) {
      return 'Concluída em $when';
    }
    if (desc != null && desc.isNotEmpty) {
      return when == null ? desc : '$desc · $when';
    }
    return 'Etapa concluída';
  }
  if (desc != null && desc.isNotEmpty) return desc;
  if (atual) return 'Próxima etapa';
  return 'Pendente';
}

MarcoSucesso? planoSucessoProximoMarco(List<MarcoSucesso> marcos) {
  for (final marco in marcos) {
    if (!marco.atingido) return marco;
  }
  return null;
}

String planoSucessoRevisaoIso(DateTime data) {
  final y = data.year.toString().padLeft(4, '0');
  final m = data.month.toString().padLeft(2, '0');
  final d = data.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String planoSucessoStickyLabel({
  required bool hasPlano,
  required MarcoSucesso? proximo,
}) {
  if (!hasPlano) return 'Criar plano';
  if (proximo != null) return 'Marcar etapa';
  return 'Remarcar revisão';
}

String planoSucessoHubSubtitle({required String base}) => base;

String planoSucessoEtapasValue(int done, int total) => '$done/$total';

String planoSucessoEtapasHint({
  required int done,
  required int total,
  required MarcoSucesso? proximo,
}) {
  if (total <= 0) return 'Nenhuma etapa ainda';
  if (proximo == null) return 'Todas as etapas feitas';
  return '$done de $total · próxima etapa';
}

String planoSucessoRevisaoMetricValue(DateTime? data) {
  if (data == null) return '—';
  return planoSucessoRevisaoLabel(data);
}

String planoSucessoRevisaoMetricHint(DateTime? data) {
  if (data == null) return 'Sem data de revisão';
  return 'Próxima revisão';
}

class PlanoSucessoRevisaoOpcao {
  const PlanoSucessoRevisaoOpcao({
    required this.dias,
    required this.data,
    required this.label,
    required this.subtitle,
  });

  final int dias;
  final DateTime data;
  final String label;
  final String subtitle;
}

const planoSucessoRevisaoHorizontes = [7, 14, 21, 30, 45, 60];

List<PlanoSucessoRevisaoOpcao> planoSucessoRevisaoOpcoes(DateTime today) {
  final base = DateTime(today.year, today.month, today.day);
  return [
    for (final dias in planoSucessoRevisaoHorizontes)
      PlanoSucessoRevisaoOpcao(
        dias: dias,
        data: base.add(Duration(days: dias)),
        label: 'Em $dias dias',
        subtitle: planoSucessoRevisaoLabel(base.add(Duration(days: dias))),
      ),
  ];
}

DateTime? planoSucessoRevisaoOpcaoSelecionada({
  required List<PlanoSucessoRevisaoOpcao> opcoes,
  required DateTime atual,
}) {
  final day = DateTime(atual.year, atual.month, atual.day);
  for (final opcao in opcoes) {
    if (opcao.data.year == day.year &&
        opcao.data.month == day.month &&
        opcao.data.day == day.day) {
      return opcao.data;
    }
  }
  return null;
}
