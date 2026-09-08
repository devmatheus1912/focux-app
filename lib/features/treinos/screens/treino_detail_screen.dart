import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../exercicios/screens/widgets/substituir_exercicio_bottom_sheet.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_inset_picker_option.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../constants/treinos_layout.dart';
import '../utils/treino_detail_grouping.dart';
import '../utils/treino_prescription_rules.dart';
import '../widgets/montar_por_modelo.dart';
import '../widgets/treino_detail_help_sheet.dart';
import '../widgets/treino_home_sheet.dart';
import '../widgets/treino_inset_sheet.dart';
import '../widgets/prescription_editor_sheet.dart';
import '../widgets/treino_prescription_video_block.dart';
import '../data/workout_builder_preset.dart';

part 'treino_detail_screen_body.part.dart';
part 'treino_detail_screen_exercises.part.dart';
part 'treino_detail_screen_rows.part.dart';
part 'treino_detail_screen_sheets.part.dart';
part 'treino_detail_screen_states.part.dart';

String _workoutContextLabel(Treino treino, String? alunoNome) =>
    treinoDetailContextLabel(treino, alunoNome);

String _displayWorkoutName(String raw) => displayWorkoutName(raw);

String _workoutGroupLabel(TreinoExercicioItem te) => treinoDetailGroupLabel(te);

bool _showsExerciseGroupHeader(List<TreinoExercicioItem> items, int index) =>
    treinoDetailShowsGroupHeader(items, index);

int _localIndexInGroup(List<TreinoExercicioItem> items, int index) =>
    treinoDetailLocalIndexInGroup(items, index);

int _groupExerciseCount(List<TreinoExercicioItem> items, int index) =>
    treinoDetailGroupExerciseCount(items, index);

bool _isLastInExerciseGroup(List<TreinoExercicioItem> items, int index) =>
    treinoDetailIsLastInGroup(items, index);

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
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Treino',
            onBack: () => _popTreinoDetail(context, alunoId: alunoId),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como montar este treino',
                onTap: () async {
                  AnalyticsService.instance.track(
                    ProductEvents.treinoDetailHelpOpened,
                    props: {'id': treinoId},
                  );
                  await showTreinoDetailHelpSheet(context);
                },
              ),
              _TreinoDetailOverflowButton(
                treinoId: treinoId,
                alunoId: alunoId,
                isDark: isDark,
              ),
            ],
          ),
          body: treinoAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 6),
                ),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  title: 'Não conseguimos carregar o treino',
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(treinoProvider(treinoId)),
                ),
            data:
                (treino) => _TrackOnce(
                  onFirst: () {
                    AnalyticsService.instance.track(
                      ProductEvents.treinoDetailViewed,
                      props: {
                        'id': treinoId,
                        'exercicios': treino.exercicios.length,
                      },
                    );
                  },
                  child: _TreinoDetailFresh(
                    treino: treino,
                    treinoId: treinoId,
                    alunoId: alunoId,
                    alunoNome: alunoNome,
                    isDark: isDark,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _TreinoDetailFresh extends ConsumerStatefulWidget {
  const _TreinoDetailFresh({
    required this.treino,
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
  });

  final Treino treino;
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final bool isDark;

  @override
  ConsumerState<_TreinoDetailFresh> createState() => _TreinoDetailFreshState();
}

class _TreinoDetailFreshState extends ConsumerState<_TreinoDetailFresh> {
  late DateTime _fetchedAt;

  @override
  void initState() {
    super.initState();
    _fetchedAt = DateTime.now();
  }

  Future<void> _refresh() async {
    AnalyticsService.instance.track(
      ProductEvents.treinoDetailRefreshed,
      props: {'id': widget.treinoId},
    );
    ref.invalidate(treinoProvider(widget.treinoId));
    await ref.read(treinoProvider(widget.treinoId).future);
    if (mounted) setState(() => _fetchedAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final treino = ref
        .watch(treinoProvider(widget.treinoId))
        .maybeWhen(data: (value) => value, orElse: () => widget.treino);
    return _TreinoDetailBody(
      treino: treino,
      treinoId: widget.treinoId,
      alunoId: widget.alunoId,
      alunoNome: widget.alunoNome,
      isDark: widget.isDark,
      freshnessLabel: FxHubFreshness.fromFetchedAt(_fetchedAt),
      onRefresh: _refresh,
      ref: ref,
    );
  }
}

class _TreinoDetailOverflowButton extends ConsumerWidget {
  const _TreinoDetailOverflowButton({
    required this.treinoId,
    required this.alunoId,
    required this.isDark,
  });

  final int treinoId;
  final int? alunoId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treino = ref.watch(treinoProvider(treinoId)).asData?.value;
    if (treino == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Opções do treino',
      onPressed: () => _openTreinoDetailMenu(
        context: context,
        ref: ref,
        treino: treino,
        treinoId: treinoId,
        alunoId: alunoId,
        isDark: isDark,
      ),
      icon: const Icon(Icons.more_horiz_rounded),
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

Future<T?> _showTreinoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showFxHomeSheet<T>(
    context,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}

class _TrackOnce extends StatefulWidget {
  const _TrackOnce({required this.onFirst, required this.child});

  final VoidCallback onFirst;
  final Widget child;

  @override
  State<_TrackOnce> createState() => _TrackOnceState();
}

class _TrackOnceState extends State<_TrackOnce> {
  @override
  void initState() {
    super.initState();
    widget.onFirst();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
