import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_unread.dart';

void main() {
  test('uses pulse on first paint before inbox is ready', () {
    expect(
      dashboardResolveUnreadCount(
        pulseUnread: 5,
        inboxReady: false,
        inboxUnread: 0,
      ),
      5,
    );
  });

  test('prefers live inbox when ready (avoids stale pulse cache)', () {
    expect(
      dashboardResolveUnreadCount(
        pulseUnread: 5,
        inboxReady: true,
        inboxUnread: 0,
      ),
      0,
    );
    expect(
      dashboardResolveUnreadCount(
        pulseUnread: 0,
        inboxReady: true,
        inboxUnread: 3,
      ),
      3,
    );
  });
}
