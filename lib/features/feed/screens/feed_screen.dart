import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';
import '../widgets/feed_comments_sheet.dart';
import '../widgets/feed_composer_sheet.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';

part 'feed_screen_state.part.dart';
part 'feed_screen_widgets.part.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}
