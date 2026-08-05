import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_scroll_logic.dart';

void main() {
  test('floating chip is disabled to avoid duplicate Ver prioridades', () {
    expect(dashboardShowsFloatingPrioritiesChip(80), isFalse);
    expect(dashboardShowsFloatingPrioritiesChip(150), isFalse);
  });

  test('sticky priorities only after panel leaves the viewport', () {
    expect(dashboardShowsStickyPrioritiesAction(80), isFalse);
    expect(dashboardShowsStickyPrioritiesAction(219), isFalse);
    expect(dashboardShowsStickyPrioritiesAction(220), isTrue);
  });

  test('scroll visual state changes on sticky priorities threshold', () {
    expect(
      dashboardScrollVisualStateChanged(previousOffset: 50, newOffset: 55),
      isFalse,
    );
    expect(
      dashboardScrollVisualStateChanged(previousOffset: 70, newOffset: 90),
      isFalse,
    );
    expect(
      dashboardScrollVisualStateChanged(previousOffset: 200, newOffset: 230),
      isTrue,
    );
  });
}
