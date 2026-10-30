import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../exercicios/screens/widgets/substituir_exercicio_bottom_sheet.dart';
import '../data/treino_repository.dart';
import '../utils/prescricao_serie.dart';
import '../providers/treinos_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../constants/treinos_layout.dart';
import '../utils/treino_criacao_fluxo.dart';
import '../utils/treino_blocos.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../exercicios/models/exercicio_criado.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../utils/treino_detail_grouping.dart';
import '../utils/treino_prescription_rules.dart';
import '../utils/rotina_aviso.dart';
import '../widgets/ficha_contexto_treino.dart';
import '../widgets/modelo_contexto_treino.dart';
import '../widgets/treino_assign_sheet.dart';
import '../widgets/montar_por_modelo.dart';
import '../widgets/estado_do_salvo.dart';
import '../widgets/treino_no_lugar.dart';
import '../models/metodo_exercicio.dart';
import '../utils/combinados.dart';
import '../widgets/ficha_acoes.dart';
import '../utils/divisao_catalogo.dart';
import '../utils/semana_da_fila.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../widgets/treino_detail_help_sheet.dart';
import '../widgets/treino_inset_sheet.dart';
import '../widgets/prescription_editor_sheet.dart';
import '../data/workout_builder_preset.dart';
import '../../../l10n/app_localizations.dart';

part 'treino_detail_screen_body.part.dart';
part 'treino_detail_screen_exercises.part.dart';
part 'treino_detail_screen_rows.part.dart';
part 'treino_detail_screen_sheets.part.dart';
part 'treino_detail_screen_states.part.dart';

String _workoutContextLabel(Treino treino, String? alunoNome) =>
    treinoDetailContextLabel(treino, alunoNome);

String _displayWorkoutName(String raw) => displayWorkoutName(raw);

/// Abre a folha de prescrição de um exercício do treino (também usada pela
/// tela de adicionar). Devolve `true` se salvou.
Future<bool?> showPrescricaoDoItem(
  BuildContext context, {
  required int treinoId,
  required TreinoExercicioItem item,
  required TreinoRepository repo,
  List<TreinoExercicioItem> outrosNoBloco = const [],
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return _showTreinoSheet<bool>(
    context: context,
    builder: (_) => _EditPrescriptionSheet(
      treinoId: treinoId,
      item: item,
      isDark: isDark,
      repo: repo,
      outrosNoBloco: outrosNoBloco,
    ),
  );
}

class TreinoDetailScreen extends ConsumerStatefulWidget {
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;

  /// Aberto por um modelo de ficha (e não pela ficha de um aluno).
  final int? modeloId;

  const TreinoDetailScreen({
    super.key,
    required this.treinoId,
    this.alunoId,
    this.alunoNome,
    this.modeloId,
  });

  @override
  ConsumerState<TreinoDetailScreen> createState() => _TreinoDetailScreenState();
}

class _TreinoDetailScreenState extends ConsumerState<TreinoDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final treinoId = widget.treinoId;
    final alunoId = widget.alunoId;
    final alunoNome = widget.alunoNome;
    final treinoAsync = ref.watch(treinoProvider(treinoId));
    final treinoCarregado = treinoAsync.asData?.value;
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
            title:
                treinoCarregado == null
                    ? 'Treino'
                    : _displayWorkoutName(treinoCarregado.nome),
            subtitle:
                treinoCarregado == null || alunoId != null || widget.modeloId != null
                    ? null
                    : _workoutContextLabel(treinoCarregado, alunoNome),
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
                alunoNome: alunoNome,
                modeloId: widget.modeloId,
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
                    modeloId: widget.modeloId,
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
    required this.modeloId,
    required this.isDark,
  });

  final Treino treino;
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final int? modeloId;
  final bool isDark;

  @override
  ConsumerState<_TreinoDetailFresh> createState() => _TreinoDetailFreshState();
}

class _TreinoDetailFreshState extends ConsumerState<_TreinoDetailFresh> {
  Future<void> _refresh() async {
    AnalyticsService.instance.track(
      ProductEvents.treinoDetailRefreshed,
      props: {'id': widget.treinoId},
    );
    ref.invalidate(treinoProvider(widget.treinoId));
    await ref.read(treinoProvider(widget.treinoId).future);
  }

  @override
  Widget build(BuildContext context) {
    final treinoAsync = ref.watch(treinoProvider(widget.treinoId));
    final treino = treinoAsync.maybeWhen(
      data: (value) => value,
      orElse: () => widget.treino,
    );
    return _TreinoDetailBody(
      treino: treino,
      salvando: treinoAsync.isLoading,
      treinoId: widget.treinoId,
      alunoId: widget.alunoId,
      alunoNome: widget.alunoNome,
      modeloId: widget.modeloId,
      isDark: widget.isDark,
      onRefresh: _refresh,
      ref: ref,
    );
  }
}

class _TreinoDetailOverflowButton extends ConsumerWidget {
  const _TreinoDetailOverflowButton({
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.modeloId,
    required this.isDark,
  });

  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final int? modeloId;
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
        alunoNome: alunoNome,
        modeloId: modeloId,
        isDark: isDark,
      ),
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}

void _popTreinoDetail(BuildContext context, {int? alunoId}) {
  if (alunoId != null) {
    safePopOrGo(context, '/alunos/$alunoId/rotina');
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
