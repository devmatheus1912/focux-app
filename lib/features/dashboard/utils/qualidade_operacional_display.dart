import '../../../core/money/fx_money.dart';
import '../data/qualidade_operacional.dart';

const qualidadeComoCalculamos =
    'Índice 0–100: metade ticket vs um recorte de mercado configurado, metade retenção (ativos / ativos+inativos) vs o mesmo recorte.';

/// Ticket médio ausente (sem mensalidades / base zerada) — não compete com mercado.
bool qualidadeTicketUnavailable(double ticketPessoal) => ticketPessoal <= 0;

String _qualidadeMoneyLabel(double reais) =>
    formatBrlCents((reais * 100).round(), showDecimals: false);

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
    return 'Acima do mercado $mercado';
  }
  return 'Mercado $mercado';
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

class QualidadeNextAction {
  const QualidadeNextAction({
    required this.label,
    required this.route,
    required this.shellTab,
  });

  final String label;
  final String route;
  final bool shellTab;
}

QualidadeNextAction qualidadeNextAction(QualidadeOperacionalData data) {
  if (data.retencaoPessoal < data.retencaoMercado) {
    return const QualidadeNextAction(
      label: 'Ver retenção',
      route: '/retencao',
      shellTab: false,
    );
  }
  if (data.ticketPessoal < data.ticketMercado) {
    return const QualidadeNextAction(
      label: 'Mensalidades',
      route: '/financeiro',
      shellTab: false,
    );
  }
  return const QualidadeNextAction(
    label: 'Ver alunos',
    route: '/alunos',
    shellTab: true,
  );
}

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
