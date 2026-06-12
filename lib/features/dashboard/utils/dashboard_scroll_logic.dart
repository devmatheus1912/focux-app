/// Regras puras de scroll do hub personal (chip flutuante vs sticky).
const double dashboardStickyChipMinOffset = 80;
const double dashboardFloatingChipMaxOffset = 220;
const double dashboardScrollOffsetEpsilon = 2;

bool dashboardShowsFloatingPrioritiesChip(double offset) =>
    offset >= dashboardStickyChipMinOffset &&
    offset < dashboardFloatingChipMaxOffset;

bool dashboardShowsStickyChip(double offset) =>
    offset >= dashboardStickyChipMinOffset;

bool dashboardScrollOffsetMeaningfullyChanged(
  double previousOffset,
  double newOffset,
) =>
    (newOffset - previousOffset).abs() >= dashboardScrollOffsetEpsilon;

bool dashboardScrollVisualStateChanged({
  required double previousOffset,
  required double newOffset,
}) {
  final wasFloating = dashboardShowsFloatingPrioritiesChip(previousOffset);
  final nowFloating = dashboardShowsFloatingPrioritiesChip(newOffset);
  final wasSticky = dashboardShowsStickyChip(previousOffset);
  final nowSticky = dashboardShowsStickyChip(newOffset);
  return wasFloating != nowFloating || wasSticky != nowSticky;
}
