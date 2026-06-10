import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_followup_store.dart';
import '../data/aluno_list_preferences_store.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_followup_provider.dart';
import '../providers/alunos_provider.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_motion.dart';
import '../constants/alunos_list_filters.dart';
import '../utils/aluno_display_utils.dart';
import '../utils/alunos_list_utils.dart';
import '../widgets/aluno_avatar.dart';
import '../../../core/widgets/fx_premium_entrance.dart';

export '../constants/alunos_list_filters.dart';

part 'alunos_list_screen_state.part.dart';
part 'alunos_list_screen_cards.part.dart';
part 'alunos_list_screen_actions.part.dart';

/// Fade na borda direita para indicar scroll horizontal nos filtros.
class _HorizontalScrollPeek extends StatelessWidget {
  const _HorizontalScrollPeek({
    required this.child,
    required this.showPeek,
  });

  final Widget child;
  final bool showPeek;

  @override
  Widget build(BuildContext context) {
    if (!showPeek) return child;

    final base = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: 'Deslize horizontalmente para ver mais filtros',
          child: child,
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    base.withValues(alpha: 0),
                    base.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AlunosListScreen extends ConsumerStatefulWidget {
  final AlunoFiltro initialFiltro;

  const AlunosListScreen({super.key, this.initialFiltro = AlunoFiltro.todos});

  @override
  ConsumerState<AlunosListScreen> createState() => _AlunosListScreenState();
}
