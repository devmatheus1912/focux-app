import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/alunos/data/aluno_repository.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'chat_inbox_screen_state.part.dart';
part 'chat_inbox_screen_widgets.part.dart';

final chatInboxProvider = FutureProvider<List<ChatInboxItem>>((ref) async {
  return ChatRepository(ref.read(apiClientProvider)).inbox();
});

final chatInboxUnreadProvider = FutureProvider<List<ChatInboxItem>>((
  ref,
) async {
  return ChatRepository(ref.read(apiClientProvider)).inboxUnread();
});

final chatInboxArchivedProvider = FutureProvider<List<ChatInboxItem>>((
  ref,
) async {
  return ChatRepository(ref.read(apiClientProvider)).inboxArchived();
});

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}
