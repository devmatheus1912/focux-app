import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';
import '../utils/treinos_list_labels.dart';
import '../constants/treinos_layout.dart';
import '../widgets/treino_assign_sheet.dart';
import '../widgets/treino_home_sheet.dart';
import '../widgets/treino_inset_sheet.dart';
import '../widgets/treinos_list_help_sheet.dart';

part 'treinos_list_screen_state.part.dart';
part 'treinos_list_sheets.part.dart';
part 'treinos_list_header.part.dart';
part 'treinos_list_cards.part.dart';

class TreinosListScreen extends ConsumerWidget {
  final int? alunoId;
  final String? alunoNome;

  const TreinosListScreen({super.key, this.alunoId, this.alunoNome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TreinosListView(alunoId: alunoId, alunoNome: alunoNome);
  }
}

/// Hint sob a biblioteca curta — preenche o vão acima do sticky CTA.
String? treinosSparseHint({required int count}) {
  if (count <= 0) return null;
  if (count == 1) {
    return 'Só um treino. Crie outro plano base para variar a semana do aluno.';
  }
  if (count < 3) {
    return 'Biblioteca enxuta. Mais um plano preenche o espaço e acelera a atribuição.';
  }
  return null;
}

/// Folga inferior da lista com sticky CTA fora do scroll.
double treinosListBottomPad({
  required BuildContext context,
  required bool stickyVisible,
}) {
  if (stickyVisible) return TokensStrip.s2;
  return TreinosLayout.listBottomGap(context);
}

class _TreinosListView extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const _TreinosListView({required this.alunoId, required this.alunoNome});

  @override
  ConsumerState<_TreinosListView> createState() => _TreinosListViewState();
}
