import '../data/qualidade_operacional.dart';

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
      label: 'Ver financeiro',
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
