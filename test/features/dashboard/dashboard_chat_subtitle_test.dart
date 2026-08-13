import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_chat_subtitle.dart';

void main() {
  test('prefers unread count from pulse over conversation count', () {
    expect(
      dashboardChatShortcutSubtitle(unreadCount: 3, conversationCount: 4),
      '3 não lidas',
    );
    expect(
      dashboardChatShortcutSubtitle(unreadCount: 1, conversationCount: 9),
      '1 não lida',
    );
  });

  test('falls back to conversations then empty CTA', () {
    expect(
      dashboardChatShortcutSubtitle(unreadCount: 0, conversationCount: 4),
      '4 conversas',
    );
    expect(
      dashboardChatShortcutSubtitle(unreadCount: 0, conversationCount: 0),
      'Abrir conversas',
    );
  });
}
