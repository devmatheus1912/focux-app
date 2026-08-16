import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_unread.dart';

void main() {
  test('chat unread vem do pulse BFF (SSOT)', () {
    expect(dashboardChatUnreadCount(5), 5);
    expect(dashboardChatUnreadCount(null), 0);
    expect(dashboardChatUnreadCount(-1), 0);
  });
}
