import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../widgets/chat_inbox_help_sheet.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/alunos/data/aluno_repository.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../utils/chat_inbox_display.dart';
import '../utils/aluno_picker_list.dart';

part 'chat_inbox_screen_state.part.dart';
part 'chat_inbox_screen_widgets.part.dart';

final chatInboxHomeProvider = FutureProvider<ChatInboxHomeBundle>((ref) async {
  return ChatRepository(ref.read(apiClientProvider)).inboxHome();
});

final chatInboxProvider = FutureProvider<List<ChatInboxItem>>((ref) async {
  return (await ref.watch(chatInboxHomeProvider.future)).inbox;
});

final chatInboxUnreadProvider = FutureProvider<List<ChatInboxItem>>((
  ref,
) async {
  return (await ref.watch(chatInboxHomeProvider.future)).unread;
});

final chatInboxArchivedProvider = FutureProvider<List<ChatInboxItem>>((
  ref,
) async {
  return (await ref.watch(chatInboxHomeProvider.future)).archived;
});

void invalidateChatInboxCaches(WidgetRef ref) {
  ref.invalidate(chatInboxHomeProvider);
}

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}
