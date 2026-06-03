import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_bottom_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../exercicios/screens/widgets/padrao_movimento_grid.dart';
import '../../exercicios/data/template_splits.dart';
import '../../exercicios/screens/widgets/template_split_picker.dart';
import '../data/treino_repository.dart';
import '../data/workout_builder_preset.dart';
import '../providers/treinos_provider.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../exercicios/screens/widgets/substituir_exercicio_bottom_sheet.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/services/biblioteca_bootstrap.dart';
import '../../exercicios/services/biblioteca_sync_status.dart';
import '../../exercicios/screens/widgets/exercise_video_preview_sheet.dart';
import '../../exercicios/screens/widgets/exercise_video_upload_strip.dart';
import '../data/exercise_prescription_memory.dart';
import '../data/exercise_prescription_memory_store.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';
import '../services/recent_exercise_usage_store.dart';
import '../utils/exercise_picker_filter.dart';
import '../utils/exercise_picker_sort.dart';
import '../utils/exercise_picker_suggestions.dart';
import '../utils/exercise_search_highlight.dart';
import '../utils/exercise_picker_library_label.dart';

part 'add_exercicio_to_treino_screen_widgets_a.part.dart';
part 'add_exercicio_to_treino_screen_widgets_b.part.dart';
part 'add_exercicio_to_treino_screen_widgets_c.part.dart';
part 'add_exercicio_to_treino_screen_widgets_d.part.dart';
part 'add_exercicio_to_treino_screen_actions_a.part.dart';
part 'add_exercicio_to_treino_screen_actions_b.part.dart';




class AddExercicioToTreinoScreen extends ConsumerStatefulWidget {
  final int treinoId;
  final int? alunoId;
  const AddExercicioToTreinoScreen({
    super.key,
    required this.treinoId,
    this.alunoId,
  });

  @override
  ConsumerState<AddExercicioToTreinoScreen> createState() =>
      _AddExercicioToTreinoScreenState();
}

class _AddExercicioToTreinoScreenState
    extends ConsumerState<AddExercicioToTreinoScreen> {
  Exercicio? _selecionado;
  final _seriesCtrl = TextEditingController(text: '3');
  final _repCtrl = TextEditingController(text: '10-12');
  final _descansoCtrl = TextEditingController(text: '60');
  final _cargaCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final _grupoSupersetCtrl = TextEditingController(text: '1');
  final _videoPicker = ImagePicker();
  String _presetId = 'hypertrophy';
  String _tipoSerie = 'NORMAL';
  int _tabIndex = 0;
  bool _loading = false;
  bool _mediaLoading = false;
  String? _error;
  final _buscaCtrl = TextEditingController();
  String _buscaQuery = '';
  bool _videoExpanded = false;
  bool _seedingBiblioteca = false;
  bool _bottomBarHidden = false;
  bool _prescriptionEditorOpen = false;
  ExercisePickerFilter _pickerFilter = const ExercisePickerFilter();
  String? _alunoFilterNome;
  final _prescriptionAnchor = GlobalKey();
  final _scrollCtrl = ScrollController();
  bool _prescriptionInView = false;
  Timer? _searchDebounce;
  Timer? _celebrateVideoTimer;
  bool _celebrateVideoSuccess = false;
  List<int> _recentIds = const [];
  ExercisePrescriptionMemory? _lastPrescription;

  @override
  void initState() {
    super.initState();
    _applyPreset('hypertrophy', notify: false);
    _buscaCtrl.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        final next = _buscaCtrl.text.trim();
        if (next != _buscaQuery) setState(() => _buscaQuery = next);
      });
    });
    _scrollCtrl.addListener(_syncPrescriptionVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureBiblioteca();
      _applyAlunoEquipmentFilter();
      _loadPickerMemory();
    });
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repCtrl.dispose();
    _descansoCtrl.dispose();
    _cargaCtrl.dispose();
    _observacoesCtrl.dispose();
    _grupoSupersetCtrl.dispose();
    _buscaCtrl.dispose();
    _searchDebounce?.cancel();
    _celebrateVideoTimer?.cancel();
    _scrollCtrl
      ..removeListener(_syncPrescriptionVisibility)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(exerciciosProvider);
    final treinoAsync = ref.watch(treinoProvider(widget.treinoId));
    final alreadyInTreinoIds = _treinoExercicioIds(treinoAsync);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        safePopOrGo(context, '/treinos/${widget.treinoId}');
      },
      child: FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Adicionar Exercício',
        subtitle: treinoAsync.maybeWhen(
          data: (treino) => displayWorkoutName(treino.nome),
          orElse: () => 'Montando treino',
        ),
        onBack:
            () => safePopOrGo(context, '/treinos/${widget.treinoId}'),
      ),
      body: SafeArea(
        bottom: false,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): () {
              if (_selecionado != null && !_loading) _submitAndContinue();
            },
            const SingleActivator(LogicalKeyboardKey.escape): () {
              safePopOrGo(context, '/treinos/${widget.treinoId}');
            },
          },
          child: Focus(
            autofocus: true,
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: BibliotecaSyncStatus.instance,
              builder: (context, _) {
                final sync = BibliotecaSyncStatus.instance;
                if (!sync.syncing) return const SizedBox.shrink();
                return _BibliotecaSyncBanner(
                  message: sync.message ?? 'Preparando biblioteca...',
                  isDark: isDark,
                  primary: primary,
                  showProgress: true,
                );
              },
            ),
            Expanded(
              child: exerciciosAsync.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: SkeletonList(count: 4),
                    ),
                error:
                    (e, _) => _ExercicioErrorState(
                      isDark: isDark,
                      primary: primary,
                      onRetry: () => ref.invalidate(exerciciosProvider),
                    ),
                data:
                    (exercicios) {
                      if (exercicios.isEmpty) {
                        return _EmptyBibliotecaState(
                          loading: _seedingBiblioteca,
                          isDark: isDark,
                          primary: primary,
                          onImport: () async {
                            setState(() => _seedingBiblioteca = true);
                            try {
                              await ref
                                  .read(exercicioRepositoryProvider)
                                  .importarSeedPremiumV1();
                              ref.invalidate(exerciciosProvider);
                            } finally {
                              if (mounted) {
                                setState(() => _seedingBiblioteca = false);
                              }
                            }
                          },
                        );
                      }

                      return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null && (_tabIndex != 0 || _selecionado == null))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: _AddExerciseErrorBanner(message: _error!),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollCtrl,
                            padding: EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              _showPrescriptionPanel
                                  ? (_selecionado != null
                                          ? 152
                                          : 48) +
                                      MediaQuery.paddingOf(context).bottom
                                  : 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AddExerciseTabStrip(
                                  selectedIndex: _tabIndex,
                                  primary: primary,
                                  isDark: isDark,
                                  onChanged: (index) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _tabIndex = index);
                                  },
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.02),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey(_tabIndex),
                                    child: _buildTabContent(
                                      context: context,
                                      exercicios: _visibleExercicios(exercicios),
                                      allExercicios: exercicios,
                                      totalLibraryCount: exercicios.length,
                                      isDark: isDark,
                                      primary: primary,
                                      alreadyInTreinoIds: alreadyInTreinoIds,
                                    ),
                                  ),
                                ),
                                if (_showPrescriptionPanel) ...[
                                  KeyedSubtree(
                                    key: _prescriptionAnchor,
                                    child: const SizedBox(height: 0),
                                  ),
                                  const SizedBox(height: 18),
                                  _PrescriptionSectionHeader(
                                    isDark: isDark,
                                    primary: primary,
                                    globalPresetMode: _selecionado == null,
                                  ),
                                  if (_lastPrescription != null) ...[
                                    const SizedBox(height: 10),
                                    _RepeatPrescriptionBanner(
                                      memory: _lastPrescription!,
                                      isDark: isDark,
                                      primary: primary,
                                      onApply: _applyLastPrescription,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _PresetSelector(
                                    selectedId: _presetId,
                                    primary: primary,
                                    isDark: isDark,
                                    onSelected: _applyPreset,
                                  ),
                                  const SizedBox(height: 20),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final wide = constraints.maxWidth > 600;
                                      final fieldStyle = AppTypography.inter(
                                        color: ink,
                                        fontWeight: FontWeight.w700,
                                      );
                                      final seriesField = TextFormField(
                                        controller: _seriesCtrl,
                                        decoration: _fxInputDecoration(
                                          label: 'Séries',
                                          isDark: isDark,
                                          primary: primary,
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: fieldStyle,
                                      );
                                      final repField = TextFormField(
                                        controller: _repCtrl,
                                        decoration: _fxInputDecoration(
                                          label: 'Repetições',
                                          isDark: isDark,
                                          primary: primary,
                                        ),
                                        style: fieldStyle,
                                      );
                                      final descansoField = TextFormField(
                                        controller: _descansoCtrl,
                                        decoration: _fxInputDecoration(
                                          label: 'Descanso (segundos)',
                                          isDark: isDark,
                                          primary: primary,
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: fieldStyle,
                                      );
                                      final cargaField = TextFormField(
                                        controller: _cargaCtrl,
                                        decoration: _fxInputDecoration(
                                          label: 'Carga alvo (kg)',
                                          helper: 'Opcional',
                                          isDark: isDark,
                                          primary: primary,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: fieldStyle,
                                      );
                                      if (!wide) {
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: seriesField),
                                                const SizedBox(width: 12),
                                                Expanded(child: repField),
                                              ],
                                            ),
                                            const SizedBox(height: TokensStrip.s4),
                                            Row(
                                              children: [
                                                Expanded(child: descansoField),
                                                const SizedBox(width: 12),
                                                Expanded(child: cargaField),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: seriesField),
                                          const SizedBox(width: 12),
                                          Expanded(child: repField),
                                          const SizedBox(width: 12),
                                          Expanded(child: descansoField),
                                          const SizedBox(width: 12),
                                          Expanded(child: cargaField),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: TokensStrip.s4),
                                  _SerieTypeSelector(
                                    value: _tipoSerie,
                                    primary: primary,
                                    isDark: isDark,
                                    onChanged:
                                        (value) =>
                                            setState(() => _tipoSerie = value),
                                  ),
                                  if (_tipoSerie == 'SUPERSET') ...[
                                    const SizedBox(height: TokensStrip.s4),
                                    TextFormField(
                                      controller: _grupoSupersetCtrl,
                                      decoration: _fxInputDecoration(
                                        label: 'Grupo do superset',
                                        helper:
                                            'Use o mesmo número em exercícios que devem ficar juntos.',
                                        isDark: isDark,
                                        primary: primary,
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: AppTypography.inter(
                                        color: ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                  if (_tipoSerie == 'DROPSET') ...[
                                    const SizedBox(height: 12),
                                    _ModeHint(
                                      icon: Icons.trending_down_rounded,
                                      text:
                                          'Drop set: registre reduções de carga nas observações ou no acompanhamento por série.',
                                      color: EagleTokens.warn,
                                      isDark: isDark,
                                    ),
                                  ],
                                  const SizedBox(height: TokensStrip.s4),
                                  TextFormField(
                                    controller: _observacoesCtrl,
                                    decoration: _fxInputDecoration(
                                      label: 'Observações de execução',
                                      isDark: isDark,
                                      primary: primary,
                                    ),
                                    minLines: 2,
                                    maxLines: 4,
                                    style: AppTypography.inter(
                                      color: ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_tabIndex != 0)
                          _ActivePrescriptionStrip(
                            presetId: _presetId,
                            series: _seriesCtrl.text,
                            repeticoes: _repCtrl.text,
                            descanso: _descansoCtrl.text,
                            tipoSerie: _tipoSerie,
                            isDark: isDark,
                            primary: primary,
                            onEdit: _openPrescriptionEditor,
                          ),
                        if (_tabIndex == 0 &&
                            _selecionado != null &&
                            !_bottomBarHidden)
                          _StickyAddExerciseBar(
                            error: _error,
                            loading: _loading,
                            isDark: isDark,
                            onSubmit: _submit,
                            onContinue: _submitAndContinue,
                          ),
                      ],
                    );
                    },
              ),
            ),
          ],
        ),
      ),
        ),
      ),
      ),
    );
  }
}

