import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../notificacoes/data/notificacoes_repository.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../utils/dashboard_home_coach_store.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_home_focus_store.dart';
import '../utils/dashboard_home_snapshot.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_scroll_logic.dart';
import '../utils/dashboard_onboarding_logic.dart';
import '../constants/dashboard_layout.dart';
import '../widgets/dashboard_shimmer_loading.dart';
import '../widgets/dashboard_command_center_section.dart';
import '../widgets/dashboard_error_state.dart';
import '../widgets/dashboard_home_primary_slivers.dart';
import '../widgets/dashboard_home_secondary_block.dart';
import '../widgets/dashboard_quick_search_sheet.dart';
import '../widgets/dashboard_home_help_sheet.dart';
import '../widgets/dashboard_tools_section.dart';
import '../widgets/dashboard_command_center_sticky_header.dart';
import '../utils/dashboard_screen_helpers.dart';
import '../utils/dashboard_home_client_cache.dart';

part 'personal_dashboard_screen_state.part.dart';
part 'personal_dashboard_screen_build.part.dart';

class PersonalDashboardScreen extends ConsumerStatefulWidget {
  const PersonalDashboardScreen({super.key});

  @override
  ConsumerState<PersonalDashboardScreen> createState() =>
      _PersonalDashboardScreenState();
}
