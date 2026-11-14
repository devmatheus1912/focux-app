import '../../../l10n/app_localizations.dart';
import '../data/financeiro_repository.dart';

/// Segmentos da tela única do Financeiro.
enum FinanceiroSegmento { mensalidades, recorrencias, resultados }

String financeiroSegmentoLabel(FinanceiroSegmento segmento, S s) =>
    switch (segmento) {
      FinanceiroSegmento.mensalidades => s.financeiroSegMensalidades,
      FinanceiroSegmento.recorrencias => s.financeiroSegRecorrencias,
      FinanceiroSegmento.resultados => s.financeiroSegResultados,
    };

/// `?aba=` da rota `/financeiro`; desconhecido volta para Mensalidades.
FinanceiroSegmento financeiroSegmentoDaRota(String? aba) => switch (aba) {
  'recorrencias' => FinanceiroSegmento.recorrencias,
  'resultados' => FinanceiroSegmento.resultados,
  _ => FinanceiroSegmento.mensalidades,
};

/// `?filtro=` da rota de Financeiro; nulo quando não vem ou não existe.
MensalidadeFiltro? financeiroFiltroDaRota(String? filtro) => switch (filtro) {
  'atrasadas' => MensalidadeFiltro.atrasadas,
  'abertas' => MensalidadeFiltro.abertas,
  'pagas' => MensalidadeFiltro.pagas,
  'todas' => MensalidadeFiltro.todas,
  _ => null,
};

String financeiroHubSubtitle({String? freshness}) {
  final fresh = freshness?.trim();
  return fresh == null || fresh.isEmpty ? 'Cobranças e resultados' : fresh;
}

/// Ferramentas da lista — sticky é Nova; resto sob Mais / chip.
enum FinanceiroListaToolId { marcarLote, cancelarLote }

/// "Marcar lote" aparece na faixa dos filtros só com 2 ou mais mensalidades
/// em aberto na lista (com uma, a baixa única resolve).
bool financeiroMostrarMarcarLote(int emAberto) => emAberto >= 2;

/// Barra do lote, que só existe durante a seleção: confirmar no chip,
/// cancelar em "Mais". Fora dela, "Marcar lote" mora na faixa dos filtros
/// ([financeiroMostrarMarcarLote]) e no toque longo da linha.
({FinanceiroListaToolId? foldChip, List<FinanceiroListaToolId> mais})
financeiroListaToolsDoLote() => (
  foldChip: FinanceiroListaToolId.marcarLote,
  mais: const [FinanceiroListaToolId.cancelarLote],
);

String financeiroListaToolLabel(
  FinanceiroListaToolId id, {
  required bool modoSelecao,
  required int selecionados,
}) => switch (id) {
  FinanceiroListaToolId.marcarLote => financeiroLotePagoChipLabel(
    modoSelecao: modoSelecao,
    selecionados: selecionados,
  ),
  FinanceiroListaToolId.cancelarLote => 'Cancelar seleção',
};

/// Ações do menu "⋮" do detalhe. Cobrar (chat ou PIX) e Marcar como paga
/// ficam na barra de baixo; Cancelar vem sempre por último.
enum MensalidadeDetailActionId {
  edit,
  contato,
  aluno,
  desfazerPagamento,
  cancelar,
}

List<MensalidadeDetailActionId> mensalidadeDetailMaisActions({
  required bool pending,
  bool pago = false,
}) => [
  if (pending || pago) MensalidadeDetailActionId.edit,
  if (pending) MensalidadeDetailActionId.contato,
  MensalidadeDetailActionId.aluno,
  if (pago) MensalidadeDetailActionId.desfazerPagamento,
  if (pending) MensalidadeDetailActionId.cancelar,
];

String mensalidadeDetailActionLabel(MensalidadeDetailActionId id, S s) =>
    switch (id) {
      MensalidadeDetailActionId.edit => 'Editar',
      MensalidadeDetailActionId.contato => 'Registrar contato',
      MensalidadeDetailActionId.aluno => 'Abrir aluno',
      MensalidadeDetailActionId.cancelar => s.mensalidadeCancelarAcao,
      MensalidadeDetailActionId.desfazerPagamento =>
        s.mensalidadeDesfazerPagamentoAcao,
    };

String mensalidadeFiltroLabel(MensalidadeFiltro f, S s) => switch (f) {
  MensalidadeFiltro.abertas => s.financeiroFiltroAbertas,
  MensalidadeFiltro.atrasadas => s.financeiroFiltroAtrasadas,
  MensalidadeFiltro.pagas => s.financeiroFiltroPagas,
  MensalidadeFiltro.todas => s.financeiroFiltroTodas,
};

/// Cabeçalho de grupo da lista: "Outubro 2026" a partir de `yyyy-MM[-dd]`.
String financeiroMesCabecalho(String mesReferencia) {
  final raw = mesReferencia.trim();
  final ano = raw.length >= 4 ? int.tryParse(raw.substring(0, 4)) : null;
  final mes = raw.length >= 7 ? int.tryParse(raw.substring(5, 7)) : null;
  if (ano == null || mes == null) return financeiroMensalidadeMesLabel(raw);
  return financeiroMesTitulo(mes, ano);
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

/// Título da linha: a cobrança avulsa diz o que é; a mensal, o mês.
String financeiroMensalidadeTitulo(Mensalidade m) {
  final d = m.descricao?.trim();
  if (d != null && d.isNotEmpty) return d;
  return financeiroMensalidadeMesPorExtenso(m.mesReferencia);
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

String financeiroVencimentoDashboardSubtitle({
  required String mesReferencia,
  String? vencimento,
  required String status,
}) {
  final atrasado = status == 'ATRASADO';
  final raw =
      (vencimento != null && vencimento.trim().isNotEmpty)
          ? vencimento.trim()
          : mesReferencia;
  return '${atrasado ? 'Atrasado' : 'Vencendo'} · ${financeiroIsoDateLabel(raw)}';
}

String financeiroSalvarMensalidadeConfirmTitle() => 'Salvar mensalidade?';

String financeiroLancarMensalidadeConfirmTitle() => 'Lançar mensalidade?';

String financeiroSalvarMensalidadeTileLabel() => 'Salvar';

String financeiroLancarMensalidadeTileLabel() => 'Lançar';

bool financeiroStatusAberto(String status) {
  final s = status.trim().toUpperCase();
  return s == 'PENDENTE' || s == 'ATRASADO';
}

String financeiroLotePagoChipLabel({
  required bool modoSelecao,
  required int selecionados,
}) {
  if (!modoSelecao) return 'Marcar lote';
  if (selecionados <= 0) return 'Selecione cobranças';
  return selecionados == 1
      ? 'Marcar 1 cobrança paga'
      : 'Marcar $selecionados pagas';
}

String financeiroLotePagoConfirmMessage(int cobrancas) =>
    cobrancas == 1
        ? 'Marca como paga esta cobrança selecionada.'
        : 'Marca como pagas estas $cobrancas cobranças selecionadas.';

String financeiroLotePagoSuccess(int cobrancas) =>
    cobrancas == 1
        ? 'Cobrança marcada como paga.'
        : '$cobrancas cobranças marcadas como pagas.';

String financeiroAlunoPickerValue(String? nome) {
  final n = nome?.trim();
  if (n == null || n.isEmpty) return 'Selecionar';
  return n;
}

String financeiroContatoWhenLabel(String? registradoEm) =>
    financeiroMensalidadePagoEmLabel(registradoEm);

String financeiroContatoSubtitle(String? observacao, String? registradoEm) {
  final when = financeiroContatoWhenLabel(registradoEm);
  final note = observacao?.trim() ?? '';
  if (note.isEmpty) return when;
  if (when == 'Ainda em aberto') return note;
  return '$note · $when';
}

String financeiroMesCurto(int mes) => const [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
][mes - 1];
