import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_scroll_logic.dart';

void main() {
  group('dashboardShowsStickyPrioritiesAction', () {
    test('sticky always off — Mais prioridades fixo no painel (#33)', () {
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
        isFalse,
      );
      expect(
        dashboardShowsStickyPrioritiesAction(
          panelOffscreen: true,
          showPrioritiesLink: true,
          toolsBlocksSticky: true,
        ),
        isFalse,
      );
    });
  });

  group('dashboardToolsBlocksSticky', () {
    test('blocks when tools enter the bottom sticky band', () {
      expect(
        dashboardToolsBlocksSticky(
          toolsTopGlobal: 500,
          viewportHeight: 800,
          stickyBandFromBottom: 200,
          currentlyBlocked: false,
        ),
        isTrue,
      );
      expect(
        dashboardToolsBlocksSticky(
          toolsTopGlobal: 650,
          viewportHeight: 800,
          stickyBandFromBottom: 200,
          currentlyBlocked: false,
        ),
        isFalse,
      );
      expect(
        dashboardToolsBlocksSticky(
          toolsTopGlobal: 620,
          viewportHeight: 800,
          stickyBandFromBottom: 200,
          currentlyBlocked: true,
        ),
        isTrue,
      );
    });
  });

  test('inline Mais prioridades some when sticky overlay is visible', () {
    expect(
      dashboardShowsInlinePrioritiesLink(
        showPrioritiesLink: true,
        stickyVisible: false,
      ),
      isTrue,
    );
    expect(
      dashboardShowsInlinePrioritiesLink(
        showPrioritiesLink: true,
        stickyVisible: true,
      ),
      isFalse,
    );
    expect(
      dashboardShowsInlinePrioritiesLink(
        showPrioritiesLink: false,
        stickyVisible: false,
      ),
      isFalse,
    );
  });

  test('scroll offset epsilon avoids rebuild noise', () {
    expect(dashboardScrollOffsetMeaningfullyChanged(50, 51), isFalse);
    expect(dashboardScrollOffsetMeaningfullyChanged(50, 53), isTrue);
  });

  group('dashboardScrollVisualStateChanged', () {
    test('changes only when sticky inputs flip', () {
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
      expect(
        dashboardScrollVisualStateChanged(
          previousPanelOffscreen: true,
          newPanelOffscreen: true,
          previousToolsBlocked: false,
          newToolsBlocked: true,
        ),
        isTrue,
      );
    });
  });

  group('dashboardPanelIsOffscreen', () {
    test('uses hysteresis so the overlay does not flicker at the edge', () {
      expect(
        dashboardPanelIsOffscreen(
          panelBottom: 80,
          headerReserve: 80,
          currentlyOffscreen: false,
        ),
        isTrue,
      );
      expect(
        dashboardPanelIsOffscreen(
          panelBottom: 90,
          headerReserve: 80,
          currentlyOffscreen: false,
        ),
        isFalse,
      );
      expect(
        dashboardPanelIsOffscreen(
          panelBottom: 90,
          headerReserve: 80,
          currentlyOffscreen: true,
        ),
        isTrue,
      );
      expect(
        dashboardPanelIsOffscreen(
          panelBottom: 105,
          headerReserve: 80,
          currentlyOffscreen: true,
        ),
        isFalse,
      );
    });
  });
}
