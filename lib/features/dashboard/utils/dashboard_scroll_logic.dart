/// Regras puras de scroll do hub personal.
///
/// «Ver prioridades» no painel fica visível no topo; no sticky (acima do dock)
/// só aparece depois que o painel de próximas ações sai da viewport.
const double dashboardScrollOffsetEpsilon = 2;

/// Sticky só quando o painel de próximas ações saiu da viewport (medido via
/// GlobalKey em runtime), ainda há prioridades extras, e o bloco de tools
/// não está na faixa do chip (evita cobrir «Mais ferramentas» / catálogo).
bool dashboardShowsStickyPrioritiesAction({
  required bool panelOffscreen,
  required bool showPrioritiesLink,
  bool toolsBlocksSticky = false,
}) => panelOffscreen && showPrioritiesLink && !toolsBlocksSticky;

/// Tools entraram na faixa inferior (sticky + dock) — some o overlay.
bool dashboardToolsBlocksSticky({
  required double toolsTopGlobal,
  required double viewportHeight,
  required double stickyBandFromBottom,
  required bool currentlyBlocked,
  double hysteresis = 28,
}) {
  final threshold = viewportHeight - stickyBandFromBottom;
  if (currentlyBlocked) {
    return toolsTopGlobal < threshold + hysteresis;
  }
  return toolsTopGlobal < threshold;
}

/// Inline «Mais prioridades» some quando o overlay sticky já cobre o CTA.
bool dashboardShowsInlinePrioritiesLink({
  required bool showPrioritiesLink,
  required bool stickyVisible,
}) => showPrioritiesLink && !stickyVisible;

/// Histerese: evita ligar/desligar o overlay a cada pixel na borda.
bool dashboardPanelIsOffscreen({
  required double panelBottom,
  required double headerReserve,
  required bool currentlyOffscreen,
  double hysteresis = 24,
}) {
  if (currentlyOffscreen) {
    return panelBottom <= headerReserve + hysteresis;
  }
  return panelBottom <= headerReserve;
}

bool dashboardScrollOffsetMeaningfullyChanged(
  double previousOffset,
  double newOffset,
) => (newOffset - previousOffset).abs() >= dashboardScrollOffsetEpsilon;

/// Só vale a pena reconstruir a árvore quando a visibilidade sticky muda.
bool dashboardScrollVisualStateChanged({
  required bool previousPanelOffscreen,
  required bool newPanelOffscreen,
  bool previousToolsBlocked = false,
  bool newToolsBlocked = false,
}) =>
    previousPanelOffscreen != newPanelOffscreen ||
    previousToolsBlocked != newToolsBlocked;
