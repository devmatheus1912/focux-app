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
    required this.collapseQuickLinks,
    required this.suppressSecondaryEmptyCtas,
    required this.compactCommandSticky,
    required this.hideFeaturedTools,
    required this.omitSecondarySections,
    required this.collapsePulseBody,
    required this.maxVisibleNextActions,
  });

  final bool focusMode;
  final bool dayFocusCoversRetention;
  final bool collapseAttention;
  final bool collapseAderencia;
  final bool collapseFinance;
  final bool hideSecondaryRiskCtas;
  final bool hidePromoBanners;
  /// Atalhos rápidos começam recolhidos (sempre — dock já cobre nav).
  final bool collapseQuickLinks;
  /// Esconde CTAs de empty (aderência/pulso) que competem com o P1.
  final bool suppressSecondaryEmptyCtas;
  /// Sticky da Central mais compacto (menos título duplicado).
  final bool compactCommandSticky;
  /// No modo foco, some o grid “featured” de Mais ferramentas (só header).
  final bool hideFeaturedTools;
  /// No foco/dense: não monta Aderência / Financeiro / Mais ferramentas.
  final bool omitSecondarySections;
  /// No foco: Pulso só header (sparkline/tendência recolhidos).
  final bool collapsePulseBody;
  final int maxVisibleNextActions;

  /// Quantos cards de risco "Precisa de atenção" pode mostrar.
  ///
  /// Quando o Foco do dia já cobre retenção, o risco vira dono único da
  /// narrativa lá em cima (P0 na Central) — aqui zeramos para não ecoar o
  /// mesmo sinal duas vezes. Sem esse dono, seguimos a densidade normal.
  static int attentionRiskLimit({
    required bool dayFocusCoversRetention,
    required bool focusMode,
    required bool riskDominante,
  }) {
    if (dayFocusCoversRetention) return 0;
    if (focusMode) return 1;
    return riskDominante ? 2 : 4;
  }

  /// Vencimentos em "Precisa de atenção" — some quando o Foco já é cobrança.
  static int attentionVencLimit({
    required DashboardDayFocus dayFocus,
    required bool dayFocusCoversRetention,
    required bool focusMode,
  }) {
    if (dayFocusCoversRetention &&
        dayFocus.headline == 'Cobrança e retenção hoje') {
      return 0;
    }
    return focusMode ? 1 : 2;
  }

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
    final dense = focusMode || covers;
    return DashboardHomeFocusRules(
      focusMode: focusMode,
      dayFocusCoversRetention: covers,
      collapseAttention: dense || riscoAlto > 3,
      collapseAderencia: true,
      collapseFinance: dense || receitaAtual <= 0,
      hideSecondaryRiskCtas: dense,
      // Promo/ativação nunca compete com retomada — mesmo com foco desligado.
      hidePromoBanners: dense,
      collapseQuickLinks: true,
      suppressSecondaryEmptyCtas: dense,
      compactCommandSticky: focusMode,
      hideFeaturedTools: focusMode,
      omitSecondarySections: focusMode,
      collapsePulseBody: focusMode,
      maxVisibleNextActions: focusMode ? 2 : 3,
    );
  }
}

/// Copy de aderência sem ecoar o Foco do dia.
abstract final class DashboardAderenciaCopy {
  DashboardAderenciaCopy._();

  static String emptyBody({required bool retentionFocus}) {
    if (retentionFocus) {
      return 'Ranking volta com treinos. Prioridade de contato já está no topo.';
    }
    return 'Quando alunos treinarem, a aderência aparece aqui com ranking automático.';
  }

  static String stoppedBody({required bool retentionFocus}) {
    if (retentionFocus) {
      return 'Sem treinos na semana. Prioridade de contato já está no topo.';
    }
    return 'Acione alunos sem treino esta semana pela agenda ou pela base.';
  }
}
