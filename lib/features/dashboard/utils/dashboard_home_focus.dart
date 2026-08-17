import 'dashboard_day_focus.dart';

/// Regras de foco da Home — densidade e dedupe de narrativa.
class DashboardHomeFocusRules {
  const DashboardHomeFocusRules({
    required this.focusMode,
    required this.dayFocusCoversRetention,
    required this.collapseAttention,
    required this.collapseRadar,
    required this.collapseAderencia,
    required this.collapseFinance,
    required this.hideSecondaryRiskCtas,
    required this.hidePromoBanners,
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
  /// Radar começa recolhido em foco/retenção — peso abaixo do fold.
  final bool collapseRadar;
  final bool collapseAderencia;
  final bool collapseFinance;
  final bool hideSecondaryRiskCtas;
  final bool hidePromoBanners;
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
        (dayFocus.kind == DashboardDayFocusKind.cobrancaRetencao ||
            dayFocus.headline == 'Cobrança e retenção hoje')) {
      return 0;
    }
    return focusMode ? 1 : 2;
  }

  static bool coversRetention(DashboardDayFocus focus) {
    if (focus.coversRetention != null) return focus.coversRetention!;
    final kind = focus.kind;
    if (kind != null) {
      return kind == DashboardDayFocusKind.cobrancaRetencao ||
          kind == DashboardDayFocusKind.retomadaUrgente ||
          kind == DashboardDayFocusKind.risco;
    }
    return focus.headline == 'Cobrança e retenção hoje' ||
        focus.headline == 'Retomada urgente da base' ||
        focus.headline == 'Acompanhar alunos em risco';
  }

  /// Default: crise (retenção/risco) sempre liga o Foco no arranque —
  /// o persistido só vale em dia normal. Toggle da sessão continua livre.
  static bool defaultFocusMode({
    required DashboardDayFocus dayFocus,
    required bool riskDominante,
    bool? persisted,
  }) {
    if (riskDominante || coversRetention(dayFocus)) return true;
    return persisted ?? false;
  }

  static DashboardHomeFocusRules resolve({
    required bool focusMode,
    required DashboardDayFocus dayFocus,
    required int riscoAlto,
    required double receitaAtual,
  }) {
    final covers = coversRetention(dayFocus);
    final retentionGuard = covers;
    return DashboardHomeFocusRules(
      focusMode: focusMode,
      dayFocusCoversRetention: covers,
      collapseAttention: focusMode || covers || riscoAlto > 3,
      collapseRadar: focusMode || covers,
      // Retenção: ranking vazio compete com o Foco — começa recolhido.
      collapseAderencia: focusMode || covers,
      collapseFinance: focusMode || covers || receitaAtual <= 0,
      hideSecondaryRiskCtas: focusMode || covers,
      hidePromoBanners: retentionGuard || focusMode,
      suppressSecondaryEmptyCtas: focusMode || covers,
      compactCommandSticky: focusMode,
      hideFeaturedTools: focusMode,
      omitSecondarySections: focusMode,
      collapsePulseBody: focusMode,
      maxVisibleNextActions: (focusMode || covers) ? 2 : 3,
    );
  }
}

/// Copy de aderência sem ecoar o Foco do dia.
abstract final class DashboardAderenciaCopy {
  DashboardAderenciaCopy._();

  static String emptyBody({required bool retentionFocus}) {
    if (retentionFocus) {
      return 'Ranking volta com treinos na semana.';
    }
    return 'Quando alunos treinarem, a aderência aparece aqui com ranking automático.';
  }

  static String stoppedBody({required bool retentionFocus}) {
    if (retentionFocus) {
      return 'Sem check-ins nesta semana.';
    }
    return 'Acione alunos sem treino esta semana pela agenda ou pela base.';
  }
}

/// CTA "Relatório" só quando o ranking tem dado real — some no empty/retenção.
bool dashboardShowAderenciaRelatorio({
  required bool focusMode,
  required bool coversRetention,
  required Iterable<int> weeklyCheckins,
}) {
  if (focusMode || coversRetention) return false;
  return weeklyCheckins.any((n) => n > 0);
}
