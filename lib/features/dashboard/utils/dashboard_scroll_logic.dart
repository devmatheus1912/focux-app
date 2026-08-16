/// Regras puras de scroll do hub personal.
///
/// «Ver prioridades» no painel fica visível no topo; no sticky (acima do dock)
/// só aparece depois que o painel de próximas ações sai da viewport.
const double dashboardScrollOffsetEpsilon = 2;

/// @Deprecated — chip flutuante removido (duplicava sticky + painel).
bool dashboardShowsFloatingPrioritiesChip(double offset) => false;

/// Sticky só quando o painel de próximas ações saiu da viewport (medido via
/// GlobalKey em runtime) e ainda há prioridades extras para ver.
bool dashboardShowsStickyPrioritiesAction({
  required bool panelOffscreen,
  required bool showPrioritiesLink,
}) => panelOffscreen && showPrioritiesLink;

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

/// Só vale a pena reconstruir a árvore quando a visibilidade do painel
/// realmente muda (evita rebuilds a cada pixel de scroll).
bool dashboardScrollVisualStateChanged({
  required bool previousPanelOffscreen,
  required bool newPanelOffscreen,
}) => previousPanelOffscreen != newPanelOffscreen;
