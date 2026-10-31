import '../../../core/money/fx_money.dart';
import '../data/qualidade_operacional.dart';
import '../../../l10n/pt.dart';

final qualidadeComoCalculamos =
    ptS.qualidadeIndiceDe0A100;

/// Abaixo disso o índice oscila com um aluno só.
const qualidadeAlunosMinimos = 5;

bool qualidadeBasePequena(int? alunosAtivos) =>
    alunosAtivos != null && alunosAtivos < qualidadeAlunosMinimos;

/// Ticket médio ausente (sem mensalidades / base zerada) — não compete com mercado.
bool qualidadeTicketUnavailable(double ticketPessoal) => ticketPessoal <= 0;

String _qualidadeMoneyLabel(double reais) =>
    formatBrlCompact((reais * 100).round());

String qualidadeTicketValueLabel(double ticketPessoal) {
  if (qualidadeTicketUnavailable(ticketPessoal)) return ptS.qualidadeSemTicket;
  return _qualidadeMoneyLabel(ticketPessoal);
}

String qualidadeTicketHint({
  required double ticketPessoal,
  required double ticketMercado,
}) {
  final mercado = _qualidadeMoneyLabel(ticketMercado);
  if (qualidadeTicketUnavailable(ticketPessoal)) {
    return ptS.qualidadeIndisponivelReferencia(mercado);
  }
  if (ticketPessoal >= ticketMercado) {
    return ptS.qualidadeAcimaDaReferencia(mercado);
  }
  return ptS.qualidadeReferencia(mercado);
}

enum QualidadeScoreBand { excellent, good, attention }

QualidadeScoreBand qualidadeScoreBand(int score) {
  if (score >= 80) return QualidadeScoreBand.excellent;
  if (score >= 50) return QualidadeScoreBand.good;
  return QualidadeScoreBand.attention;
}

String qualidadeScoreLabel(int score) => switch (qualidadeScoreBand(score)) {
  QualidadeScoreBand.excellent => ptS.qualidadeExcelente,
  QualidadeScoreBand.good => ptS.qualidadeBom,
  QualidadeScoreBand.attention => ptS.retencaoMetAtencao,
};

String qualidadeRetencaoHint({
  required int retencaoPessoal,
  required int retencaoMercado,
}) =>
    retencaoPessoal >= retencaoMercado
        ? ptS.qualidadeAcimaDaReferencia2(retencaoMercado)
        : ptS.qualidadeReferencia2(retencaoMercado);

/// Insight coerente com as métricas do card (não só o texto cru do BE).
String qualidadeRecomendacaoDisplay(QualidadeOperacionalData data) {
  final retencaoOk = data.retencaoPessoal >= data.retencaoMercado;
  final ticketOk = data.ticketPessoal >= data.ticketMercado;
  if (data.ticketPessoal <= 0 && retencaoOk) {
    return ptS.qualidadeRetencaoForteCadastreMensalidadesPara;
  }
  if (retencaoOk && !ticketOk) {
    return ptS.qualidadeRetencaoForteFoqueEmPrecificacao;
  }
  if (!retencaoOk && ticketOk) {
    return ptS.qualidadeAtencaoARetencaoVejaQuem;
  }
  if (!retencaoOk && !ticketOk) {
    return ptS.qualidadeAtencaoARetencaoEPrecificacao;
  }
  final be = data.recomendacao.trim();
  if (be.isNotEmpty) return be;
  return ptS.qualidadeOperacaoSaudavelContinueAcompanhandoA;
}
