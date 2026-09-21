import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../data/aluno_list_preferences_store.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_motion.dart';
import '../constants/alunos_layout.dart';
import '../constants/alunos_list_filters.dart';
import '../widgets/aluno_list_card.dart';
import '../widgets/alunos_error_scaffold.dart';
import '../utils/alunos_l10n.dart';
import '../utils/alunos_home_client_cache.dart';
import '../utils/alunos_list_utils.dart';
import '../utils/alunos_microcopy.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../growth/utils/migracao_vagas_logic.dart';
import '../widgets/alunos_list_help_sheet.dart';
import '../widgets/alunos_loading_scaffold.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_horizontal_scroll_peek.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_inset_picker_option.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';

export '../constants/alunos_list_filters.dart';

part 'alunos_list_screen_state.part.dart';
part 'alunos_list_screen_filters.part.dart';
part 'alunos_list_screen_header.part.dart';
part 'alunos_list_screen_body.part.dart';
part 'alunos_list_screen_cards.part.dart';
part 'alunos_list_screen_actions.part.dart';

class AlunosListScreen extends ConsumerStatefulWidget {
  final AlunoFiltro initialFiltro;

  const AlunosListScreen({super.key, this.initialFiltro = AlunoFiltro.todos});

  @override
  ConsumerState<AlunosListScreen> createState() => _AlunosListScreenState();
}
