import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/screens/widgets/substituir_exercicio_bottom_sheet.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

part 'treino_detail_screen_body.part.dart';
part 'treino_detail_screen_exercises.part.dart';
part 'treino_detail_screen_rows.part.dart';
part 'treino_detail_screen_sheets.part.dart';
part 'treino_detail_screen_states.part.dart';

String _workoutContextLabel(Treino treino, String? alunoNome) {
  final name = alunoNome?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (treino.isTemplate) return 'Template base';
  return 'Plano base';
}

String _formatLoadKg(double? value) {
  if (value == null || value <= 0) return '—';
  if (value == value.roundToDouble()) return '${value.toStringAsFixed(0)}kg';
  return '${value.toStringAsFixed(1)}kg';
}

String _displayWorkoutName(String raw) {
  var name = raw.trim();
  if (name.isEmpty) return name;
  const fixes = {
    ' Forca': ' Força',
    ' forca': ' Força',
    ' FORCA': ' Força',
    'Forca ': 'Força ',
    'Forca': 'Força',
  };
  for (final entry in fixes.entries) {
    name = name.replaceAll(entry.key, entry.value);
  }
  return name;
}

String _workoutGroupLabel(TreinoExercicioItem te) {
  final grupo = te.exercicio.grupoMuscularPrimario;
  if (grupo != null) {
    final label = TaxonomyLabels.grupo[grupo];
    if (label != null && label.isNotEmpty) return label.toUpperCase();
  }
  final alvo = te.exercicio.musculoAlvo?.trim();
  if (alvo != null && alvo.isNotEmpty) return alvo.toUpperCase();
  return 'OUTROS';
}

bool _showsExerciseGroupHeader(List<TreinoExercicioItem> items, int index) {
  if (index <= 0) return true;
  return _workoutGroupLabel(items[index]) !=
      _workoutGroupLabel(items[index - 1]);
}

int _localIndexInGroup(List<TreinoExercicioItem> items, int index) {
  final group = _workoutGroupLabel(items[index]);
  var local = 1;
  for (var i = index - 1; i >= 0; i--) {
    if (_workoutGroupLabel(items[i]) != group) break;
    local++;
  }
  return local;
}

int _groupExerciseCount(List<TreinoExercicioItem> items, int index) {
  final group = _workoutGroupLabel(items[index]);
  return items.where((item) => _workoutGroupLabel(item) == group).length;
}

bool _isLastInExerciseGroup(List<TreinoExercicioItem> items, int index) {
  if (index >= items.length - 1) return true;
  return _workoutGroupLabel(items[index]) !=
      _workoutGroupLabel(items[index + 1]);
}

class TreinoDetailScreen extends ConsumerWidget {
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;

  const TreinoDetailScreen({
    super.key,
    required this.treinoId,
    this.alunoId,
    this.alunoNome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinoAsync = ref.watch(treinoProvider(treinoId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Detalhe do treino',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _popTreinoDetail(context, alunoId: alunoId);
        },
        child: Scaffold(
          backgroundColor: fxTransparent,
          body: treinoAsync.when(
            loading:
                () => SafeArea(
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(TokensStrip.s5, 86, 20, 0),
                        child: SkeletonList(count: 6),
                      ),
                      Positioned(
                        top: 8,
                        left: TokensStrip.s5 - 4,
                        child: _TreinoDetailBackButton(alunoId: alunoId),
                      ),
                    ],
                  ),
                ),
            error:
                (e, _) => _DetailErrorState(
                  isDark: isDark,
                  primary: primary,
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(treinoProvider(treinoId)),
                  onBack: () => _popTreinoDetail(context, alunoId: alunoId),
                ),
            data:
                (treino) => _TreinoDetailBody(
                  treino: treino,
                  treinoId: treinoId,
                  alunoId: alunoId,
                  alunoNome: alunoNome,
                  isDark: isDark,
                  ref: ref,
                ),
          ),
        ),
      ),
    );
  }
}

void _popTreinoDetail(BuildContext context, {int? alunoId}) {
  if (alunoId != null) {
    safePopOrGo(context, '/alunos/$alunoId/treinos-list');
    return;
  }
  safePopOrGo(context, '/treinos');
}
