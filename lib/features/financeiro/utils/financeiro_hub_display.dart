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

String financeiroMensalidadeVencimentoLabel({
  required String mesReferencia,
  String? vencimento,
}) {
  final raw = vencimento?.trim();
  if (raw != null && raw.isNotEmpty) {
    return financeiroIsoDateLabel(raw);
  }
  return financeiroMensalidadeMesPorExtenso(mesReferencia);
}

String financeiroMensalidadePagoEmLabel(String? pagoEm) {
  final raw = pagoEm?.trim() ?? '';
  if (raw.isEmpty) return 'Ainda em aberto';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
  final d = parsed.day.toString().padLeft(2, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  return '$d/$m/${parsed.year}';
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

String financeiroMensalidadeHubSubtitle({required String mes}) {
  final month = mes.trim();
  return month.isEmpty ? 'Mensalidade' : month;
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

String financeiroIsoDate(int year, int month, int day) {
  final y = year.toString().padLeft(4, '0');
  final m = month.toString().padLeft(2, '0');
  final d = day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? financeiroParseIsoDate(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  final parsed = DateTime.tryParse(t);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String financeiroIsoDateLabel(String iso) {
  final parsed = financeiroParseIsoDate(iso);
  if (parsed == null) {
    final t = iso.trim();
    if (t.isEmpty) return 'Selecionar';
    return t.length >= 10 ? t.substring(0, 10) : t;
  }
  final d = parsed.day.toString().padLeft(2, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  return '$d/$m/${parsed.year}';
}

class FinanceiroVencimentoOpcao {
  const FinanceiroVencimentoOpcao({required this.iso});

  final String iso;
  String get label => financeiroIsoDateLabel(iso);
}

List<FinanceiroVencimentoOpcao> financeiroVencimentoOpcoes({
  required String mesReferencia,
  String? atual,
}) {
  final mes = financeiroParseIsoDate(mesReferencia) ??
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  final last = DateTime(mes.year, mes.month + 1, 0);
  final isos = <String>{
    financeiroIsoDate(mes.year, mes.month, 1),
    if (last.day >= 5) financeiroIsoDate(mes.year, mes.month, 5),
    if (last.day >= 10) financeiroIsoDate(mes.year, mes.month, 10),
    if (last.day >= 15) financeiroIsoDate(mes.year, mes.month, 15),
    financeiroIsoDate(mes.year, mes.month, last.day),
  };
  final atualParsed = financeiroParseIsoDate(atual);
  if (atualParsed != null) {
    isos.add(
      financeiroIsoDate(atualParsed.year, atualParsed.month, atualParsed.day),
    );
  }
  final sorted = isos.toList()..sort();
  return [for (final iso in sorted) FinanceiroVencimentoOpcao(iso: iso)];
}

String financeiroVencimentoPickerValue(String vencimento) {
  final raw = vencimento.trim();
  if (raw.isEmpty) return 'Selecionar';
  return financeiroIsoDateLabel(raw);
}

String financeiroVencimentoAposTrocaDeMes({
  required String mesAntigo,
  required String mesNovo,
  required String vencimentoAtual,
}) {
  if (vencimentoAtual.trim() == mesAntigo.trim()) return mesNovo;
  return vencimentoAtual;
}

String financeiroVencimentoDashboardSubtitle({
  required String mesReferencia,
  String? vencimento,
  required String status,
}) {
  final atrasado = status == 'ATRASADO';
  final raw = (vencimento != null && vencimento.trim().isNotEmpty)
      ? vencimento.trim()
      : mesReferencia;
  return '${atrasado ? 'Atrasado' : 'Vencendo'} · ${financeiroIsoDateLabel(raw)}';
}

String financeiroSalvarMensalidadeConfirmTitle() => 'Salvar mensalidade?';

String financeiroSalvarMensalidadeConfirmMessage() =>
    'Valor, mês, vencimento e status entram no financeiro do aluno.';

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

const financeiroMensalidadeSecaoCobranca = 'cobranca';
const financeiroMensalidadeSecaoContatos = 'contatos';

const financeiroMensalidadeDetalheSecoes = <({String value, String label})>[
  (value: financeiroMensalidadeSecaoCobranca, label: 'Cobrança'),
  (value: financeiroMensalidadeSecaoContatos, label: 'Contatos'),
];

String financeiroContatoWhenLabel(String? registradoEm) =>
    financeiroMensalidadePagoEmLabel(registradoEm);

String financeiroContatoSubtitle(String? observacao, String? registradoEm) {
  final when = financeiroContatoWhenLabel(registradoEm);
  final note = observacao?.trim() ?? '';
  if (note.isEmpty) return when;
  if (when == 'Ainda em aberto') return note;
  return '$note · $when';
}

String financeiroContatosEmpty() => 'Nenhum contato nesta cobrança';
