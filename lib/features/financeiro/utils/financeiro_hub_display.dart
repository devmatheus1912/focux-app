import '../../alunos/utils/satellite_screen_utils.dart';

enum FinanceiroHubView { resumo, mensalidades, metricas }

String financeiroHubViewLabel(FinanceiroHubView view) {
  switch (view) {
    case FinanceiroHubView.resumo:
      return 'Resumo';
    case FinanceiroHubView.mensalidades:
      return 'Mensalidades';
    case FinanceiroHubView.metricas:
      return 'Métricas';
  }
}

String financeiroHubSubtitle({
  required FinanceiroHubView view,
  String? freshness,
}) {
  final vista = financeiroHubViewLabel(view);
  final fresh = freshness?.trim();
  if (fresh == null || fresh.isEmpty) return vista;
  return '$vista · $fresh';
}

String financeiroAlunoHubSubtitle({
  required int lancamentos,
  String? freshness,
}) {
  final count =
      lancamentos == 1 ? '1 lançamento' : '$lancamentos lançamentos';
  final fresh = freshness?.trim();
  if (fresh == null || fresh.isEmpty) return count;
  return '$count · $fresh';
}

String financeiroAlunoContextLabel(String? nome) {
  final n = nome?.trim();
  if (n == null || n.isEmpty) return 'Mensalidades deste aluno';
  return 'Mensalidades de $n';
}

String financeiroMensalidadeMesPorExtenso(String mesReferencia) {
  final raw = mesReferencia.trim();
  final parts = raw.split('-');
  if (parts.length < 2) return raw.isEmpty ? 'Sem mês' : raw;
  final ano = int.tryParse(parts[0]);
  final mes = int.tryParse(parts[1]);
  if (ano == null || mes == null) return raw;
  return financeiroMesTitulo(mes, ano);
}

String financeiroContatoTipoLabel(String tipo) {
  switch (tipo.trim().toUpperCase()) {
    case 'WHATSAPP':
      return 'WhatsApp';
    case 'LIGACAO':
      return 'Ligação';
    case 'EMAIL':
      return 'E-mail';
    case 'PRESENCIAL':
      return 'Presencial';
    case 'OUTRO':
      return 'Outro';
    default:
      return tipo;
  }
}

String financeiroMensalidadeMesLabel(String mesReferencia) {
  final raw = mesReferencia.trim();
  if (raw.length >= 7) return raw.substring(0, 7);
  return raw.isEmpty ? 'Sem mês' : raw;
}

String financeiroMensalidadeSubtitle(String status, String mesReferencia) {
  return '${financeiroMensalidadeStatusLabel(status)} · '
      '${financeiroMensalidadeMesLabel(mesReferencia)}';
}

String financeiroMensalidadeHubSubtitle({
  required String mes,
  String? freshness,
}) {
  final parts = <String>[];
  final month = mes.trim();
  if (month.isNotEmpty) parts.add(month);
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}

const _meses = [
  '',
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String financeiroMesTitulo(int mes, int ano) {
  if (mes < 1 || mes > 12) return '$mes/$ano';
  return '${_meses[mes]} $ano';
}

class FinanceiroMesOpcao {
  const FinanceiroMesOpcao({required this.ano, required this.mes});

  final int ano;
  final int mes;

  String get key => '$ano-${mes.toString().padLeft(2, '0')}';
  String get label => financeiroMesTitulo(mes, ano);
}

/// Próximo mês, atual e 16 anteriores — o recorte que a tela de métricas opera.
List<FinanceiroMesOpcao> financeiroMesOpcoes({
  DateTime? agora,
  int quantidade = 18,
}) {
  final now = agora ?? DateTime.now();
  final out = <FinanceiroMesOpcao>[];
  for (var i = -1; i < quantidade - 1; i++) {
    final d = DateTime(now.year, now.month - i, 1);
    out.add(FinanceiroMesOpcao(ano: d.year, mes: d.month));
  }
  return out;
}

String financeiroMesReferenciaKey(String atual, {DateTime? agora}) {
  final now = agora ?? DateTime.now();
  final parsed = DateTime.tryParse(atual) ?? DateTime(now.year, now.month, 1);
  return FinanceiroMesOpcao(ano: parsed.year, mes: parsed.month).key;
}

String financeiroMesReferenciaIso(String key) => '$key-01';

List<FinanceiroMesOpcao> financeiroMesReferenciaOpcoes({
  required String atual,
  DateTime? agora,
}) {
  final now = agora ?? DateTime.now();
  final parsed = DateTime.tryParse(atual) ?? DateTime(now.year, now.month, 1);
  final current = FinanceiroMesOpcao(ano: parsed.year, mes: parsed.month);
  var ops = financeiroMesOpcoes(agora: now);
  if (!ops.any((o) => o.key == current.key)) {
    ops = [current, ...ops];
  }
  return ops;
}

String financeiroSalvarMensalidadeConfirmTitle() => 'Salvar mensalidade?';

String financeiroSalvarMensalidadeConfirmMessage() =>
    'Valor, mês e status entram no financeiro do aluno.';

String financeiroLancarMensalidadeConfirmTitle() => 'Lançar mensalidade?';

String financeiroLancarMensalidadeConfirmMessage() =>
    'O valor entra na cobrança deste aluno.';

String financeiroSalvarMensalidadeTileLabel() => 'Salvar';

String financeiroLancarMensalidadeTileLabel() => 'Lançar';

bool financeiroStatusAberto(String status) =>
    status.trim().toUpperCase() != 'PAGO';

String financeiroLotePagoChipLabel({
  required bool modoSelecao,
  required int selecionados,
}) {
  if (!modoSelecao) return 'Marcar lote';
  if (selecionados <= 0) return 'Selecione alunos';
  return selecionados == 1
      ? 'Marcar 1 aluno pago'
      : 'Marcar $selecionados pagos';
}

String financeiroLotePagoConfirmMessage(int alunos) =>
    alunos == 1
        ? 'Marca como pago as mensalidades em aberto deste aluno.'
        : 'Marca como pago as mensalidades em aberto destes $alunos alunos.';

String financeiroLotePagoSuccess(int alunos) =>
    alunos == 1
        ? 'Mensalidades deste aluno marcadas como pagas.'
        : 'Mensalidades de $alunos alunos marcadas como pagas.';

String financeiroMesPickerValue(String mesReferencia) {
  final raw = mesReferencia.trim();
  if (raw.isEmpty) return 'Selecionar';
  return financeiroMensalidadeMesPorExtenso(raw);
}

String financeiroAlunoPickerValue(String? nome) {
  final n = nome?.trim();
  if (n == null || n.isEmpty) return 'Selecionar';
  return n;
}
