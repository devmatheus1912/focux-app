import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_scroll_logic.dart';

void main() {
  test('floating chip visible between sticky min and max offset', () {
    expect(dashboardShowsFloatingPrioritiesChip(79), isFalse);
    expect(dashboardShowsFloatingPrioritiesChip(80), isTrue);
    expect(dashboardShowsFloatingPrioritiesChip(150), isTrue);
    expect(dashboardShowsFloatingPrioritiesChip(219), isTrue);
    expect(dashboardShowsFloatingPrioritiesChip(220), isFalse);
  });

  test('scroll visual state changes on chip transitions', () {
    expect(
      dashboardScrollVisualStateChanged(previousOffset: 50, newOffset: 55),
      isFalse,
    );
    expect(
      dashboardScrollVisualStateChanged(previousOffset: 70, newOffset: 90),
      isTrue,
    );
    expect(
      dashboardScrollVisualStateChanged(previousOffset: 200, newOffset: 230),
      isTrue,
    );
  });
}
