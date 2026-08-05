/// Regras puras de scroll do hub personal.
///
/// «Ver prioridades» no painel fica visível no topo; no sticky só depois que
/// a linha do painel saiu da viewport — evita 2–3 CTAs iguais na mesma tela.
const double dashboardStickyPrioritiesMinOffset = 220;
const double dashboardScrollOffsetEpsilon = 2;

/// @Deprecated — chip flutuante removido (duplicava sticky + painel).
const double dashboardStickyChipMinOffset = 80;
const double dashboardFloatingChipMaxOffset =
    dashboardStickyPrioritiesMinOffset;

bool dashboardShowsFloatingPrioritiesChip(double offset) => false;

bool dashboardShowsStickyPrioritiesAction(double offset) =>
    offset >= dashboardStickyPrioritiesMinOffset;

bool dashboardShowsStickyChip(double offset) =>
    dashboardShowsStickyPrioritiesAction(offset);

bool dashboardScrollOffsetMeaningfullyChanged(
  double previousOffset,
  double newOffset,
) => (newOffset - previousOffset).abs() >= dashboardScrollOffsetEpsilon;

bool dashboardScrollVisualStateChanged({
  required double previousOffset,
  required double newOffset,
}) {
  final wasSticky = dashboardShowsStickyPrioritiesAction(previousOffset);
  final nowSticky = dashboardShowsStickyPrioritiesAction(newOffset);
  return wasSticky != nowSticky;
}
