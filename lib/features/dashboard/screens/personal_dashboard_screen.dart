import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/router/safe_navigation.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/aderencia_provider.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../notificacoes/data/notificacoes_repository.dart';
import '../../onboarding/screens/setup_onboarding_widget.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../subscription/widgets/plan_usage_banner.dart';
import '../../subscription/widgets/trial_countdown_banner.dart';
import '../../subscription/widgets/dashboard_activation_cta.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_home_focus_store.dart';
import '../utils/dashboard_home_snapshot.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_microcopy.dart';
import '../widgets/dashboard_day_focus_banner.dart';
import '../widgets/dashboard_home_header.dart';
import '../widgets/dashboard_attention_rail.dart';
import '../widgets/dashboard_collapsible_section.dart';
import '../utils/dashboard_entry_motion.dart';
import '../utils/dashboard_scroll_logic.dart';
import '../utils/dashboard_onboarding_logic.dart';
import '../constants/dashboard_layout.dart';
import '../widgets/dashboard_financial_hero_section.dart';
import '../widgets/dashboard_shimmer_loading.dart';
import '../widgets/dashboard_pulse_strip.dart';
import '../widgets/dashboard_tools_section.dart';
import '../widgets/dashboard_command_center_section.dart';
import '../widgets/dashboard_command_center_sticky_header.dart';
import '../widgets/dashboard_aderencia_semana_widget.dart';
import '../widgets/dashboard_error_state.dart';

part 'personal_dashboard_screen_state.part.dart';
part 'personal_dashboard_screen_build.part.dart';

class PersonalDashboardScreen extends ConsumerStatefulWidget {
  const PersonalDashboardScreen({super.key});

  @override
  ConsumerState<PersonalDashboardScreen> createState() =>
      _PersonalDashboardScreenState();
}
