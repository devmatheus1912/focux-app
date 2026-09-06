import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../health/data/health_repository.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../utils/aluno_detail_aluno_actions.dart';
import '../utils/aluno_detail_aluno_resolution.dart';
import '../utils/aluno_display_utils.dart';
import '../widgets/aluno360_composite_header.dart';
import '../widgets/aluno360_help_sheets.dart';
import '../widgets/aluno360_detail_evolucao_tab.dart';
import '../widgets/aluno360_detail_ferramentas_tab.dart';
import '../widgets/aluno360_detail_operacao_tab.dart';
import '../widgets/aluno360_operacao_sticky_cta.dart';
import '../widgets/aluno_detail_hero_card.dart';
import '../widgets/aluno_detail_loading_skeleton.dart';

part 'aluno_detail_screen_state.part.dart';

class AlunoDetailScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final int? initialTabIndex;
  /// Nome/foto/status from the alunos list for optimistic skeleton.
  final Aluno? listPreview;

  const AlunoDetailScreen({
    super.key,
    required this.alunoId,
    this.initialTabIndex,
    this.listPreview,
  });

  @override
  ConsumerState<AlunoDetailScreen> createState() => _AlunoDetailScreenState();
}
