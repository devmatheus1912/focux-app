import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_bottom_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../widgets/add_exercicio_help_sheet.dart';
import '../widgets/exercise_library_row.dart';
import '../widgets/exercise_library_sheet.dart';
import '../widgets/prescription_editor_sheet.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/data/exercicio_page.dart';
import '../../exercicios/data/exercise_enum_api.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicio_picker_provider.dart';
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
import '../../exercicios/screens/widgets/exercise_video_spec_tips.dart';
import '../../exercicios/screens/widgets/exercise_video_upload_strip.dart';
import '../data/exercise_prescription_memory.dart';
import '../data/exercise_prescription_memory_store.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';
import '../services/recent_exercise_usage_store.dart';
import '../utils/exercise_picker_filter.dart';
import '../utils/exercise_picker_sort.dart';
import '../utils/exercise_picker_suggestions.dart';
import '../utils/exercise_picker_library_label.dart';
import '../utils/exercise_library_meta.dart';
import '../utils/add_exercise_prescription_input.dart';

part 'add_exercicio_to_treino_screen_widgets_a.part.dart';
part 'add_exercicio_to_treino_screen_widgets_b.part.dart';
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
  bool _seedingBiblioteca = false;
  bool _bottomBarHidden = false;
  ExercisePickerFilter _pickerFilter = const ExercisePickerFilter();
  String? _alunoFilterNome;
  String? _alunoFilterWarning;
  final _scrollCtrl = ScrollController();
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
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickerAsync = ref.watch(treinoPickerHomeProvider(widget.treinoId));
    final pickerHints = pickerAsync.maybeWhen(
      data: (home) => home.uiHints,
      orElse:
          () => TreinoPickerUiHints.fallback(
            librarySize: 0,
            jaNoTreino: 0,
          ),
    );
    final treinoAsync = pickerAsync.whenData((h) => h.treino);
    final pickerApiQuery = _buildPickerApiQuery();
    final pickerPageAsync = ref.watch(exercicioPickerPageProvider(pickerApiQuery));
    final alreadyInTreinoIds = _treinoExercicioIds(treinoAsync);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Adicionar exercício',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/treinos/${widget.treinoId}');
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            centerTitle: true,
            title: 'Adicionar Exercício',
            subtitle: treinoAsync.maybeWhen(
              data: (treino) => displayWorkoutName(treino.nome),
              orElse: () => 'Montando treino',
            ),
            onBack: () => safePopOrGo(context, '/treinos/${widget.treinoId}'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Ajuda para adicionar exercícios',
                onTap: () => showAddExercicioHelpSheet(context),
              ),
              const SizedBox(width: 8),
            ],
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
                        if (sync.syncing) {
                          return _BibliotecaSyncBanner(
                            message: sync.message ?? 'Preparando biblioteca...',
                            isDark: isDark,
                            primary: primary,
                            showProgress: true,
                          );
                        }
                        final warning = sync.warningMessage;
                        if (warning != null && warning.isNotEmpty) {
                          return _BibliotecaSyncBanner(
                            message: warning,
                            isDark: isDark,
                            primary: primary,
                            showProgress: false,
                            warning: true,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Expanded(
                      child: pickerAsync.when(
                        loading:
                            () => const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: SkeletonList(count: 4),
                            ),
                        error:
                            (e, _) => FxErrorState(
                              chromeOnDark: isDark,
                              primary: primary,
                              title: 'Não conseguimos carregar os exercícios',
                              message: friendlyError(e),
                              onRetry:
                                  () => ref.invalidate(
                                    treinoPickerHomeProvider(widget.treinoId),
                                  ),
                            ),
                        data: (home) {
                          if (home.libraryCount == 0) {
                            if (_seedingBiblioteca) {
                              return const SkeletonList(count: 4);
                            }
                            return FxEmptyState(
                              icon: 'dumbbell',
                              title: 'Biblioteca padrão pronta para usar',
                              subtitle:
                                  pickerHints.emptyLibraryHint ??
                                  'Importe ~190 exercícios curados (supino, agachamento, remada...) com vídeos padrão. Depois você personaliza com os seus.',
                              action: FxEmptyAction(
                                label: 'Importar biblioteca',
                                onTap: () async {
                                  setState(() => _seedingBiblioteca = true);
                                  try {
                                    await ref
                                        .read(exercicioRepositoryProvider)
                                        .importarSeedPremiumV1();
                                    ref.invalidate(
                                      treinoPickerHomeProvider(widget.treinoId),
                                    );
                                    ref.invalidate(exerciciosProvider);
                                    ref.invalidate(exercicioPickerStatsProvider);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    FeedbackHelper.showError(
                                      context,
                                      friendlyError(e),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _seedingBiblioteca = false,
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          }

                          if (pickerPageAsync.isLoading &&
                              pickerPageAsync.valueOrNull == null) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: SkeletonList(count: 4),
                            );
                          }

                          if (pickerPageAsync.hasError &&
                              pickerPageAsync.valueOrNull == null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: FxErrorState(
                                chromeOnDark: isDark,
                                primary: primary,
                                title: 'Não conseguimos buscar exercícios',
                                message: friendlyError(pickerPageAsync.error!),
                                onRetry:
                                    () => ref.invalidate(
                                      exercicioPickerPageProvider(
                                        pickerApiQuery,
                                      ),
                                    ),
                              ),
                            );
                          }

                          final visibleExercicios = _resolveVisibleExercicios(
                            home: home,
                            pickerPage: pickerPageAsync.valueOrNull,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null &&
                                  (_tabIndex != 0 || _selecionado == null))
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    FxSettingsLayout.groupPadH,
                                    0,
                                    FxSettingsLayout.groupPadH,
                                    8,
                                  ),
                                  child: FxErrorState(
                                    chromeOnDark: isDark,
                                    primary: primary,
                                    message: _error!,
                                    onRetry:
                                        () => setState(() => _error = null),
                                  ),
                                ),
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _scrollCtrl,
                                  padding: EdgeInsets.fromLTRB(
                                    FxSettingsLayout.groupPadH,
                                    FxSettingsLayout.groupPadH,
                                    FxSettingsLayout.groupPadH,
                                    _scrollBottomInset(context),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                        duration: Duration(
                                          milliseconds: fxMotionDurationMs(
                                            context,
                                            normal: 220,
                                          ),
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, animation) {
                                          final fade = FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                          if (reduceMotionOf(context)) {
                                            return fade;
                                          }
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
                                            exercicios: visibleExercicios,
                                            libraryCount: home.libraryCount,
                                            filteredPickerCount:
                                                pickerPageAsync
                                                    .valueOrNull
                                                    ?.meta
                                                    .totalElements,
                                            uiHints: pickerHints,
                                            isDark: isDark,
                                            primary: primary,
                                            alreadyInTreinoIds:
                                                alreadyInTreinoIds,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _AddExerciseBottomDock(
                                showActions:
                                    _tabIndex == 0 &&
                                    _selecionado != null &&
                                    !_bottomBarHidden,
                                error: _error,
                                loading: _loading,
                                isDark: isDark,
                                primary: primary,
                                presetId: _presetId,
                                series: _seriesCtrl.text,
                                repeticoes: _repCtrl.text,
                                descanso: _descansoCtrl.text,
                                tipoSerie: _tipoSerie,
                                onEditPrescription: _openPrescriptionEditor,
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
      ),
    );
  }
}
