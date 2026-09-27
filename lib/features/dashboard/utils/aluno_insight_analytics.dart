import '../../../core/analytics/analytics_service.dart';
import '../data/aluno_home_insight.dart';

/// Eventos do insight da Home: só tipo e confiança, nunca números de saúde/desempenho.
class AlunoInsightAnalytics {
  AlunoInsightAnalytics._();

  static final Set<AlunoInsightTipo> _vistosNaSessao = {};

  static Map<String, Object?> props(AlunoHomeInsight insight) => {
    'tipo': insight.tipo.name,
    'confianca': insight.confianca.name,
  };

  /// `false` quando o tipo já foi registrado nesta sessão.
  static bool viewed(AlunoHomeInsight insight) {
    if (!_vistosNaSessao.add(insight.tipo)) return false;
    AnalyticsService.instance.track(
      ProductEvents.alunoInsightViewed,
      props: props(insight),
    );
    return true;
  }

  static void actionTapped(AlunoHomeInsight insight) {
    AnalyticsService.instance.track(
      ProductEvents.alunoInsightActionTapped,
      props: props(insight),
    );
  }

  static void resetSessao() => _vistosNaSessao.clear();
}
