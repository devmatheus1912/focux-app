import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../data/ia_repository.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../widgets/ia_quota_upgrade.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../providers/ia_copilot_providers.dart';
import '../widgets/ia_copilot_shell_widgets.dart';
import '../models/ia_copilot_proxima_acao.dart';
import '../widgets/ia_copilot_insight_widgets.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
part 'ia_copiloto_screen_actions.part.dart';
part 'ia_copiloto_screen_state.part.dart';
part 'ia_copiloto_screen_build.part.dart';

class IaCopilotoScreen extends ConsumerStatefulWidget {
  const IaCopilotoScreen({super.key});
  @override
  ConsumerState<IaCopilotoScreen> createState() => _IaCopilotoScreenState();
}

