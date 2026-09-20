import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';
import '../widgets/feed_comments_sheet.dart';
import '../widgets/feed_composer_sheet.dart';
import '../widgets/feed_post_card.dart';

part 'feed_screen_state.part.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

/// Hint sob a lista curta — preenche o vão acima do sticky CTA.
String? feedSparseHint({required int count}) {
  if (count <= 0) return null;
  if (count == 1) {
    return 'Só uma publicação. Publique de novo para manter o feed vivo.';
  }
  if (count < 3) {
    return 'Poucas publicações. Um post a mais preenche melhor o dia do aluno.';
  }
  return null;
}

/// Folga inferior da lista com sticky CTA fora do scroll.
double feedListBottomPad({required bool stickyVisible}) =>
    stickyVisible ? TokensStrip.s2 : TokensStrip.s5;
