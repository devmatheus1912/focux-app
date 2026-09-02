import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../data/ia_repository.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_confirm_sheet.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../widgets/ia_copiloto_help_sheet.dart';
import '../widgets/ia_quota_upgrade.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../../subscription/models/subscription_plan.dart';
import '../providers/ia_copilot_providers.dart';
import '../widgets/ia_copilot_shell_widgets.dart';
import '../models/ia_copilot_proxima_acao.dart';
import '../models/ia_copiloto_home.dart';
import '../widgets/ia_copilot_insight_widgets.dart';
import '../utils/ia_copiloto_display.dart';
import 'package:focux_app/core/widgets/fx_home_sheet.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
part 'ia_copiloto_screen_actions.part.dart';
part 'ia_copiloto_screen_state.part.dart';
part 'ia_copiloto_screen_build.part.dart';

class IaCopilotoScreen extends ConsumerStatefulWidget {
  const IaCopilotoScreen({super.key});
  @override
  ConsumerState<IaCopilotoScreen> createState() => _IaCopilotoScreenState();
}
