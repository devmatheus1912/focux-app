import '../../../core/money/fx_money.dart';
import '../data/qualidade_operacional.dart';

const qualidadeComoCalculamos =
    'Índice de 0 a 100. Metade vem do ticket médio e metade da retenção (alunos ativos sobre ativos e inativos), comparados à referência Focux.';

/// Abaixo disso o índice oscila com um aluno só.
const qualidadeAlunosMinimos = 5;

bool qualidadeBasePequena(int? alunosAtivos) =>
    alunosAtivos != null && alunosAtivos < qualidadeAlunosMinimos;

/// Ticket médio ausente (sem mensalidades / base zerada) — não compete com mercado.
bool qualidadeTicketUnavailable(double ticketPessoal) => ticketPessoal <= 0;

String _qualidadeMoneyLabel(double reais) =>
    formatBrlCompact((reais * 100).round());

String qualidadeTicketValueLabel(double ticketPessoal) {
  if (qualidadeTicketUnavailable(ticketPessoal)) return 'Sem ticket';
  return _qualidadeMoneyLabel(ticketPessoal);
}

String qualidadeTicketHint({
  required double ticketPessoal,
  required double ticketMercado,
}) {
  final mercado = _qualidadeMoneyLabel(ticketMercado);
  if (qualidadeTicketUnavailable(ticketPessoal)) {
    return 'Indisponível · referência $mercado';
  }
  if (ticketPessoal >= ticketMercado) {
    return 'Acima da referência $mercado';
  }
  return 'Referência $mercado';
}

enum QualidadeScoreBand { excellent, good, attention }

QualidadeScoreBand qualidadeScoreBand(int score) {
  if (score >= 80) return QualidadeScoreBand.excellent;
  if (score >= 50) return QualidadeScoreBand.good;
  return QualidadeScoreBand.attention;
}

String qualidadeScoreLabel(int score) => switch (qualidadeScoreBand(score)) {
  QualidadeScoreBand.excellent => 'Excelente',
  QualidadeScoreBand.good => 'Bom',
  QualidadeScoreBand.attention => 'Atenção',
};

String qualidadeRetencaoHint({
  required int retencaoPessoal,
  required int retencaoMercado,
}) =>
    retencaoPessoal >= retencaoMercado
        ? 'Acima da referência $retencaoMercado%'
        : 'Referência $retencaoMercado%';

/// Insight coerente com as métricas do card (não só o texto cru do BE).
String qualidadeRecomendacaoDisplay(QualidadeOperacionalData data) {
  final retencaoOk = data.retencaoPessoal >= data.retencaoMercado;
  final ticketOk = data.ticketPessoal >= data.ticketMercado;
  if (data.ticketPessoal <= 0 && retencaoOk) {
    return 'Retenção forte. Cadastre mensalidades para medir o ticket.';
  }
  if (retencaoOk && !ticketOk) {
    return 'Retenção forte. Foque em precificação e ticket médio.';
  }
  if (!retencaoOk && ticketOk) {
    return 'Atenção à retenção. Veja quem está em risco na base.';
  }
  if (!retencaoOk && !ticketOk) {
    return 'Atenção à retenção e precificação. Comece pela base em risco.';
  }
  final be = data.recomendacao.trim();
  if (be.isNotEmpty) return be;
  return 'Operação saudável. Continue acompanhando a base.';
}
