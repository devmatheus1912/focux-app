import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_scroll_logic.dart';

void main() {
  test('floating chip is disabled to avoid duplicate Ver prioridades', () {
    expect(dashboardShowsFloatingPrioritiesChip(80), isFalse);
    expect(dashboardShowsFloatingPrioritiesChip(150), isFalse);
  });

  group('dashboardShowsStickyPrioritiesAction', () {
    test('sticky only when panel is offscreen and link is available', () {
      expect(
        dashboardShowsStickyPrioritiesAction(
          panelOffscreen: false,
          showPrioritiesLink: true,
        ),
        isFalse,
      );
      expect(
        dashboardShowsStickyPrioritiesAction(
          panelOffscreen: true,
          showPrioritiesLink: false,
        ),
        isFalse,
      );
      expect(
        dashboardShowsStickyPrioritiesAction(
          panelOffscreen: true,
          showPrioritiesLink: true,
        ),
        isTrue,
      );
    });
  });

  test('scroll offset epsilon avoids rebuild noise', () {
    expect(dashboardScrollOffsetMeaningfullyChanged(50, 51), isFalse);
    expect(dashboardScrollOffsetMeaningfullyChanged(50, 53), isTrue);
  });

  group('dashboardScrollVisualStateChanged', () {
    test('changes only when panel visibility flips', () {
      expect(
        dashboardScrollVisualStateChanged(
          previousPanelOffscreen: false,
          newPanelOffscreen: false,
        ),
        isFalse,
      );
      expect(
        dashboardScrollVisualStateChanged(
          previousPanelOffscreen: false,
          newPanelOffscreen: true,
        ),
        isTrue,
      );
    });
  });
}
