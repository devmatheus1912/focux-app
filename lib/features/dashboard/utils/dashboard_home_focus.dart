import 'dashboard_day_focus.dart';

/// Regras de foco da Home — densidade e dedupe de narrativa.
class DashboardHomeFocusRules {
  const DashboardHomeFocusRules({
    required this.focusMode,
    required this.dayFocusCoversRetention,
    required this.collapseAttention,
    required this.collapseAderencia,
    required this.collapseFinance,
    required this.hideSecondaryRiskCtas,
    required this.hidePromoBanners,
    required this.maxVisibleNextActions,
  });

  final bool focusMode;
  final bool dayFocusCoversRetention;
  final bool collapseAttention;
  final bool collapseAderencia;
  final bool collapseFinance;
  final bool hideSecondaryRiskCtas;
  final bool hidePromoBanners;
  final int maxVisibleNextActions;

  static bool coversRetention(DashboardDayFocus focus) {
    return focus.headline == 'Cobrança e retenção hoje' ||
        focus.headline == 'Retomada urgente da base' ||
        focus.headline == 'Acompanhar alunos em risco';
  }

  /// Default: foco ligado quando a narrativa do dia é retenção/risco.
  static bool defaultFocusMode({
    required DashboardDayFocus dayFocus,
    required bool riskDominante,
    bool? persisted,
  }) {
    if (persisted != null) return persisted;
    return riskDominante || coversRetention(dayFocus);
  }

  static DashboardHomeFocusRules resolve({
    required bool focusMode,
    required DashboardDayFocus dayFocus,
    required int riscoAlto,
    required double receitaAtual,
  }) {
    final covers = coversRetention(dayFocus);
    return DashboardHomeFocusRules(
      focusMode: focusMode,
      dayFocusCoversRetention: covers,
      collapseAttention: focusMode || covers || riscoAlto > 3,
      collapseAderencia: true,
      collapseFinance: focusMode || covers || receitaAtual <= 0,
      hideSecondaryRiskCtas: focusMode || covers,
      hidePromoBanners: focusMode,
      maxVisibleNextActions: focusMode ? 2 : 3,
    );
  }
}

/// Copy de aderência sem ecoar o Foco do dia.
abstract final class DashboardAderenciaCopy {
  DashboardAderenciaCopy._();

  static String emptyBody({required bool retentionFocus}) {
    if (retentionFocus) {
      return 'Ranking volta quando houver treinos — o contato de hoje já está acima.';
    }
    return 'Quando alunos treinarem, a aderência aparece aqui com ranking automático.';
  }

  static String stoppedBody({required bool retentionFocus}) {
    if (retentionFocus) {
      return 'Sem treinos na semana. Use Revisar base se ainda precisar de outro caminho.';
    }
    return 'Acione alunos sem treino esta semana pela agenda ou pela base.';
  }
}
