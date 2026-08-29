import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_page.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/providers/exercicio_picker_provider.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../exercicios/services/biblioteca_bootstrap.dart';
import '../../exercicios/services/biblioteca_sync_status.dart';
import '../data/exercise_prescription_memory.dart';
import '../data/exercise_prescription_memory_store.dart';
import '../data/treino_repository.dart';
import '../data/workout_builder_preset.dart';
import '../providers/treinos_provider.dart';
import '../services/recent_exercise_usage_store.dart';
import '../utils/add_exercise_prescription_input.dart';
import '../utils/exercise_picker_filter.dart';
import '../utils/workout_prescription_display.dart';
import '../widgets/add_exercicio_help_sheet.dart';
import '../widgets/exercise_library_panel.dart';
import '../widgets/prescription_editor_sheet.dart';

part 'add_exercicio_to_treino_screen_actions.part.dart';

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
  final _seriesCtrl = TextEditingController(text: '3');
  final _repCtrl = TextEditingController(text: '10-12');
  final _descansoCtrl = TextEditingController(text: '60');
  final _cargaCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final _grupoSupersetCtrl = TextEditingController(text: '1');
  String _presetId = 'hypertrophy';
  String _tipoSerie = 'NORMAL';
  bool _loading = false;
  String? _error;
  bool _seedingBiblioteca = false;
  ExercisePickerFilter _pickerFilter = const ExercisePickerFilter();
  String? _alunoFilterNome;
  String? _alunoFilterWarning;
  List<int> _recentIds = const [];
  ExercisePrescriptionMemory? _lastPrescription;

  @override
  void initState() {
    super.initState();
    _applyPreset('hypertrophy', notify: false);
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
              ListenableBuilder(
                listenable: Listenable.merge([
                  _seriesCtrl,
                  _repCtrl,
                  _descansoCtrl,
                ]),
                builder:
                    (context, _) => _PrescriptionAppBarChip(
                      label: _prescriptionChipLabel(),
                      tooltip: _prescriptionTooltip(),
                      primary: primary,
                      isDark: isDark,
                      onTap: _openPrescriptionEditor,
                    ),
              ),
              TextButton(
                onPressed:
                    () => safePopOrGo(context, '/treinos/${widget.treinoId}'),
                child: Text(
                  'Concluir',
                  style: FocuxHubTypography.bodyMuted(
                    color: BrandPalette.sectionAction(primary, dark: isDark),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: CallbackShortcuts(
              bindings: {
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
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          8,
                          FxSettingsLayout.pageInset,
                          0,
                        ),
                        child: FxErrorState(
                          chromeOnDark: isDark,
                          primary: primary,
                          message: _error!,
                          onRetry: () => setState(() => _error = null),
                        ),
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
                                      treinoPickerHomeProvider(
                                        widget.treinoId,
                                      ),
                                    );
                                    ref.invalidate(exerciciosProvider);
                                    ref.invalidate(
                                      exercicioPickerStatsProvider,
                                    );
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

                          return ExerciseLibraryPanel(
                            alreadyInTreinoIds: alreadyInTreinoIds,
                            filter: _pickerFilter,
                            onFilterChanged:
                                (next) =>
                                    setState(() => _pickerFilter = next),
                            onLoadPage: _loadPickerPage,
                            onSelect: _adicionarRapido,
                            libraryTotalCount: home.libraryCount,
                            searchPlaceholder: pickerHints.searchPlaceholder,
                            recentIds: _recentIds,
                            shortcutItems: home.shortcuts,
                            header: _alunoFilterHeader(isDark, primary),
                            footer: FxSettingsGroup(
                              accent: primary,
                              children: [
                                FxSettingsTile(
                                  icon: Icons.add_rounded,
                                  accent: BrandPalette.softened(primary),
                                  label: pickerHints.createCtaLabel,
                                  value: '',
                                  showDivider: false,
                                  onTap: _openCreateExercise,
                                ),
                              ],
                            ),
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
