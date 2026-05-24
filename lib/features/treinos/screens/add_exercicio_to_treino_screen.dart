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
import '../data/exercise_prescription_memory.dart';
import '../data/exercise_prescription_memory_store.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';
import '../services/recent_exercise_usage_store.dart';
import '../utils/exercise_picker_filter.dart';
import '../utils/exercise_picker_sort.dart';
import '../utils/exercise_picker_suggestions.dart';
import '../utils/exercise_search_highlight.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

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
  ExercisePickerFilter _pickerFilter = const ExercisePickerFilter();
  String? _alunoFilterNome;
  final _prescriptionAnchor = GlobalKey();
  final _scrollCtrl = ScrollController();
  bool _prescriptionInView = false;
  Timer? _searchDebounce;
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

  void _syncPrescriptionVisibility() {
    if (_selecionado == null) {
      if (_prescriptionInView) {
        setState(() => _prescriptionInView = false);
      }
      return;
    }
    final ctx = _prescriptionAnchor.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final threshold = MediaQuery.sizeOf(ctx).height * 0.62;
    final inView = top < threshold;
    if (inView != _prescriptionInView) {
      setState(() => _prescriptionInView = inView);
    }
  }

  Future<void> _applyAlunoEquipmentFilter() async {
    final alunoId = widget.alunoId;
    if (alunoId == null) return;
    try {
      final aluno = await ref.read(alunoProvider(alunoId).future);
      if (!mounted || aluno.equipamentosDisponiveis.isEmpty) return;
      setState(() {
        _alunoFilterNome = aluno.nome;
        _pickerFilter = ExercisePickerFilter.fromAlunoEquipamentos(
          aluno.equipamentosDisponiveis,
        );
      });
    } catch (_) {
      // Mantém filtros manuais se o perfil do aluno não carregar.
    }
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
    _scrollCtrl
      ..removeListener(_syncPrescriptionVisibility)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadPickerMemory() async {
    final recent = await RecentExerciseUsageStore.recentIds();
    final last = await ExercisePrescriptionMemoryStore.load();
    if (!mounted) return;
    setState(() {
      _recentIds = recent;
      _lastPrescription = last;
    });
  }

  Future<void> _persistAfterAdd(int exercicioId) async {
    await RecentExerciseUsageStore.recordUsage(exercicioId);
    final memory = _currentPrescriptionMemory();
    await ExercisePrescriptionMemoryStore.save(memory);
    if (!mounted) return;
    setState(() => _lastPrescription = memory);
    final recent = await RecentExerciseUsageStore.recentIds();
    if (!mounted) return;
    setState(() => _recentIds = recent);
  }

  ExercisePrescriptionMemory _currentPrescriptionMemory() {
    return ExercisePrescriptionMemory(
      presetId: _presetId,
      series: int.tryParse(_seriesCtrl.text) ?? 3,
      repeticoes: _repCtrl.text,
      descansoSegundos: int.tryParse(_descansoCtrl.text) ?? 60,
      tipoSerie: _tipoSerie,
      cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
      observacoes: _observacoesCtrl.text,
      grupoSuperset:
          _tipoSerie == 'SUPERSET'
              ? int.tryParse(_grupoSupersetCtrl.text)
              : null,
    );
  }

  void _applyLastPrescription() {
    final memory = _lastPrescription;
    if (memory == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _applyPreset(memory.presetId, notify: false);
      _seriesCtrl.text = memory.series.toString();
      _repCtrl.text = memory.repeticoes;
      _descansoCtrl.text = memory.descansoSegundos.toString();
      _tipoSerie = memory.tipoSerie;
      _observacoesCtrl.text = memory.observacoes;
      if (memory.cargaKg != null) {
        _cargaCtrl.text = memory.cargaKg!.toString();
      } else {
        _cargaCtrl.clear();
      }
      if (memory.grupoSuperset != null) {
        _grupoSupersetCtrl.text = memory.grupoSuperset.toString();
      }
    });
  }

  Future<void> _ensureBiblioteca() async {
    await BibliotecaBootstrap.ensureReady(ref);
  }

  Set<int> _treinoExercicioIds(AsyncValue<Treino> treinoAsync) {
    return treinoAsync.maybeWhen(
      data:
          (treino) =>
              treino.exercicios.map((item) => item.exercicio.id).toSet(),
      orElse: () => const <int>{},
    );
  }

  void _selectExercise(Exercicio exercicio) {
    setState(() {
      _selecionado = exercicio;
      _tabIndex = 0;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _prescriptionAnchor.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      _syncPrescriptionVisibility();
    });
  }

  Future<void> _openTemplateBuilder() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (_) => FxShellScaffold(
              useMesh: true,
              appBar: FxShellAppBar(
                title: 'Montar com modelo',
                subtitle: 'Preencha os slots do treino',
                onBack: () => Navigator.pop(context),
              ),
              body: TemplateSplitPicker(
                alreadyInTreinoIds: _treinoExercicioIds(
                  ref.read(treinoProvider(widget.treinoId)),
                ),
                onAdicionar: (exercicio) async {
                  await _adicionarRapido(exercicio);
                  AnalyticsService.instance.track(
                    'template_uso',
                    props: {
                      'treinoId': widget.treinoId,
                      'exId': exercicio.id,
                    },
                  );
                },
              ),
            ),
      ),
    );
    if (mounted) ref.invalidate(treinoProvider(widget.treinoId));
  }

  void _applyPreset(String id, {bool notify = true}) {
    final preset = workoutBuilderPresetById(id);
    void apply() {
      _presetId = id;
      _seriesCtrl.text = preset.series.toString();
      _repCtrl.text = preset.repeticoes;
      _descansoCtrl.text = preset.descansoSegundos.toString();
      _tipoSerie = preset.tipoSerie;
      _observacoesCtrl.text = preset.observacoes;
      if (preset.grupoSuperset != null) {
        _grupoSupersetCtrl.text = preset.grupoSuperset.toString();
      }
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  Future<void> _submit() async {
    if (_selecionado == null) {
      setState(() {
        _error = 'Selecione um exercício.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exercicioId = _selecionado!.id;
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicioId,
            series: int.tryParse(_seriesCtrl.text) ?? 3,
            repeticoes: _repCtrl.text,
            descanso: int.tryParse(_descansoCtrl.text) ?? 60,
            cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
            observacoes: _observacoesCtrl.text,
            tipoSerie: _tipoSerie,
            grupoSuperset:
                _tipoSerie == 'SUPERSET'
                    ? int.tryParse(_grupoSupersetCtrl.text)
                    : null,
          );
      await _persistAfterAdd(exercicioId);
      if (mounted) {
        HapticFeedback.mediumImpact();
        FeedbackHelper.showSuccess(
          context,
          '${_selecionado!.nomeDisplay} adicionado ao treino.',
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _error = 'Erro ao adicionar exercício.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitAndContinue() async {
    if (_selecionado == null) {
      setState(() => _error = 'Selecione um exercício.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final nome = _selecionado!.nomeDisplay;
      final exercicioId = _selecionado!.id;
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicioId,
            series: int.tryParse(_seriesCtrl.text) ?? 3,
            repeticoes: _repCtrl.text,
            descanso: int.tryParse(_descansoCtrl.text) ?? 60,
            cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
            observacoes: _observacoesCtrl.text,
            tipoSerie: _tipoSerie,
            grupoSuperset:
                _tipoSerie == 'SUPERSET'
                    ? int.tryParse(_grupoSupersetCtrl.text)
                    : null,
          );
      await _persistAfterAdd(exercicioId);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(treinoProvider(widget.treinoId));
      setState(() {
        _selecionado = null;
        _buscaCtrl.clear();
        _loading = false;
      });
      FeedbackHelper.showSuccess(context, '$nome adicionado. Escolha o próximo.');
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao adicionar exercício.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _adicionarRapido(Exercicio exercicio) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exercicioId = exercicio.id;
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicioId,
            series: int.tryParse(_seriesCtrl.text) ?? 3,
            repeticoes: _repCtrl.text,
            descanso: int.tryParse(_descansoCtrl.text) ?? 60,
            cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
            observacoes: _observacoesCtrl.text,
            tipoSerie: _tipoSerie,
            grupoSuperset:
                _tipoSerie == 'SUPERSET'
                    ? int.tryParse(_grupoSupersetCtrl.text)
                    : null,
          );
      await _persistAfterAdd(exercicioId);
      AnalyticsService.instance.track(
        'quick_add_padrao',
        props: {'exId': exercicio.id, 'treinoId': widget.treinoId},
      );
      if (mounted) {
        ref.invalidate(treinoProvider(widget.treinoId));
        FeedbackHelper.showSuccess(
          context,
          '${exercicio.nomeDisplay} adicionado.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao adicionar exercício.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openSimilarPicker(List<Exercicio> exercicios) async {
    final alvo = _selecionado;
    if (alvo == null) return;
    Exercicio? replacement;
    setState(() => _bottomBarHidden = true);
    try {
      await showFxBottomSheet<void>(
        context: context,
        builder:
            (_) => SubstituirExercicioBottomSheet(
              alvo: alvo,
              equipamentosAluno:
                  _pickerFilter.filtrarPorAluno &&
                          _pickerFilter.equipamentosAluno.isNotEmpty
                      ? _pickerFilter.equipamentosAluno
                      : _pickerFilter.equipamento == null
                      ? null
                      : {_pickerFilter.equipamento!},
              onEscolher: (exercicio) => replacement = exercicio,
            ),
      );
    } finally {
      if (mounted) setState(() => _bottomBarHidden = false);
    }
    if (replacement != null && mounted) {
      _selectExercise(replacement!);
    }
  }

  List<Exercicio> _visibleExercicios(List<Exercicio> exercicios) {
    return applyExercisePickerFilter(exercicios, _pickerFilter);
  }

  Future<void> _openExercisePicker(
    List<Exercicio> exercicios, {
    required Set<int> alreadyInTreinoIds,
  }) async {
    HapticFeedback.selectionClick();
    setState(() => _bottomBarHidden = true);
    Exercicio? selected;
    try {
      selected = await showFxBottomSheet<Exercicio>(
        context: context,
        builder:
            (sheetContext) => _ExercisePickerSheet(
              exercicios: exercicios,
              selected: _selecionado,
              alreadyInTreinoIds: alreadyInTreinoIds,
              initialQuery: _buscaQuery,
            ),
      );
    } finally {
      if (mounted) setState(() => _bottomBarHidden = false);
    }
    if (selected != null && mounted) {
      _selectExercise(selected);
    }
  }

  Future<void> _uploadSelectedExerciseVideo() async {
    final exercicio = _selecionado;
    if (exercicio == null || _mediaLoading) return;
    final file = await _videoPicker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final messenger = FeedbackHelper.messengerOf(context);
    setState(() => _mediaLoading = true);
    FeedbackHelper.showSuccess(
      context,
      'Enviando vídeo de ${exercicio.nome}...',
    );
    try {
      final updated = await ref
          .read(exercicioRepositoryProvider)
          .uploadVideo(
            id: exercicio.id,
            bytes: await file.readAsBytes(),
            filename: file.name,
          );
      AnalyticsService.instance.track(
        'video_personal_upload',
        props: {'exId': exercicio.id, 'origin': 'treino_add_exercise'},
      );
      ref.invalidate(exerciciosProvider);
      if (!mounted) return;
      setState(() => _selecionado = updated);
      messenger.clearSnackBars();
      FeedbackHelper.showSuccess(
        context,
        'Vídeo enviado. A prévia pode levar alguns segundos para liberar.',
      );
    } catch (e) {
      if (!mounted) return;
      messenger.clearSnackBars();
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _mediaLoading = false);
      }
    }
  }

  Future<void> _removeSelectedExerciseVideo() async {
    final exercicio = _selecionado;
    if (exercicio == null || _mediaLoading) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder:
          (sheetContext) => _RemoveExerciseVideoSheet(exercicio: exercicio),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _mediaLoading = true);
    try {
      final updated = await ref
          .read(exercicioRepositoryProvider)
          .removerVideo(id: exercicio.id);
      AnalyticsService.instance.track(
        'video_personal_remove',
        props: {'exId': exercicio.id, 'origin': 'treino_add_exercise'},
      );
      ref.invalidate(exerciciosProvider);
      if (!mounted) return;
      setState(() => _selecionado = updated);
      FeedbackHelper.showSuccess(context, 'Vídeo removido do exercício.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _mediaLoading = false);
      }
    }
  }

  Future<void> _previewSelectedExerciseVideo() async {
    final exercicio = _selecionado;
    if (exercicio == null || !exercicio.hasPlayableMedia) return;
    HapticFeedback.selectionClick();
    await showExerciseVideoPreview(context, exercicio: exercicio);
  }

  Widget _buildTabContent({
    required BuildContext context,
    required List<Exercicio> exercicios,
    required bool isDark,
    required Color primary,
    required Set<int> alreadyInTreinoIds,
  }) {
    final browseHeight =
        (MediaQuery.sizeOf(context).height - 280)
            .clamp(430.0, 620.0)
            .toDouble();
    switch (_tabIndex) {
      case 1:
        return SizedBox(
          height: browseHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MontarComModeloCard(
                onTap: _openTemplateBuilder,
                isDark: isDark,
                primary: primary,
              ),
              if (_alunoFilterNome != null && _pickerFilter.filtrarPorAluno)
                _AlunoEquipmentFilterBanner(
                  alunoNome: _alunoFilterNome!,
                  equipamentos: _pickerFilter.equipamentosAluno,
                  isDark: isDark,
                  primary: primary,
                  onClear:
                      () => setState(
                        () =>
                            _pickerFilter = _pickerFilter.copyWith(clearAluno: true),
                      ),
                ),
              ExercisePickerFilterBar(
                filter: _pickerFilter,
                isDark: isDark,
                primary: primary,
                onChanged:
                    (ExercisePickerFilter next) =>
                        setState(() => _pickerFilter = next),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PadraoMovimentoGrid(
                  alreadyInTreinoIds: alreadyInTreinoIds,
                  pickerFilter: _pickerFilter,
                  onAdicionar: _selectExercise,
                  onClearFilters:
                      () => setState(() => _pickerFilter = const ExercisePickerFilter()),
                ),
              ),
            ],
          ),
        );
      default:
        final compact = _selecionado != null;
        final query = _buscaQuery.trim().toLowerCase();
        final favoriteShortcuts =
            query.length >= 2 || _pickerFilter.somenteFavoritos
                ? const <Exercicio>[]
                : sortExerciciosForPicker(
                  favoriteExercises(exercicios),
                  alreadyInTreinoIds: alreadyInTreinoIds,
                ).take(4).toList();
        final quickMatches =
            query.length < 2
                ? const <Exercicio>[]
                : sortExerciciosForPicker(
                  exercicios.where((exercicio) {
                    final haystack =
                        '${exercicio.nome} ${exercicio.musculoAlvo ?? ''} '
                                '${exercicio.equipamento ?? ''}'
                            .toLowerCase();
                    return haystack.contains(query);
                  }),
                  alreadyInTreinoIds: alreadyInTreinoIds,
                ).take(6).toList();
        final curatedSuggestions =
            !compact &&
                    query.isEmpty &&
                    favoriteShortcuts.isEmpty
                ? curatedPickerSuggestions(
                  exercicios,
                  alreadyInTreinoIds: alreadyInTreinoIds,
                  recentIds: _recentIds,
                )
                : const <Exercicio>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact) ...[
            if (_alunoFilterNome != null && _pickerFilter.filtrarPorAluno)
              _AlunoEquipmentFilterBanner(
                alunoNome: _alunoFilterNome!,
                equipamentos: _pickerFilter.equipamentosAluno,
                isDark: isDark,
                primary: primary,
                onClear:
                    () => setState(
                      () => _pickerFilter = _pickerFilter.copyWith(clearAluno: true),
                    ),
              ),
            ExercisePickerFilterBar(
              filter: _pickerFilter,
              isDark: isDark,
              primary: primary,
              onChanged: (ExercisePickerFilter next) => setState(() => _pickerFilter = next),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _buscaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar supino, agachamento, remada...',
                prefixIcon: Icon(Icons.search_rounded, color: primary),
                suffixIcon:
                    _buscaQuery.isEmpty
                        ? null
                        : IconButton(
                          onPressed: () => _buscaCtrl.clear(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                filled: true,
                fillColor:
                    isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            ],
            if (curatedSuggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _recentIds.isNotEmpty
                    ? 'Seus recentes e mais usados'
                    : 'Mais usados pelos personais',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark
                          ? EagleTokens.darkInkMute
                          : TokensStrip.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...curatedSuggestions.map(
                (exercicio) => _QuickSearchResultTile(
                  exercicio: exercicio,
                  highlightQuery: query,
                  alreadyInTreino: alreadyInTreinoIds.contains(exercicio.id),
                  primary: primary,
                  isDark: isDark,
                  onTap: () => _selectExercise(exercicio),
                ),
              ),
            ],
            if (!compact && favoriteShortcuts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Seus favoritos',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...favoriteShortcuts.map(
                (exercicio) => _QuickSearchResultTile(
                  exercicio: exercicio,
                  highlightQuery: query,
                  alreadyInTreino: alreadyInTreinoIds.contains(exercicio.id),
                  primary: primary,
                  isDark: isDark,
                  onTap: () => _selectExercise(exercicio),
                ),
              ),
            ],
            if (!compact && quickMatches.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...quickMatches.map(
                (exercicio) => _QuickSearchResultTile(
                  exercicio: exercicio,
                  highlightQuery: query,
                  alreadyInTreino: alreadyInTreinoIds.contains(exercicio.id),
                  primary: primary,
                  isDark: isDark,
                  onTap: () => _selectExercise(exercicio),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _ExercisePickerCard(
              exercicio: _selecionado,
              isDark: isDark,
              primary: primary,
              total: exercicios.length,
              compactMode: compact,
              showPrescriptionHint: !_prescriptionInView,
              onTap:
                  () => _openExercisePicker(
                    exercicios,
                    alreadyInTreinoIds: alreadyInTreinoIds,
                  ),
              mediaLoading: _mediaLoading,
              videoExpanded: _videoExpanded,
              onToggleVideo: () => setState(() => _videoExpanded = !_videoExpanded),
              onPreviewVideo: _previewSelectedExerciseVideo,
              onUploadVideo: _uploadSelectedExerciseVideo,
              onRemoveVideo: _removeSelectedExerciseVideo,
              onCreate: () async {
                final criado = await context.push<bool>('/exercicios/novo');
                if (criado == true) {
                  ref.invalidate(exerciciosProvider);
                }
              },
            ),
            if (_selecionado != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openSimilarPicker(exercicios),
                  icon: Icon(Icons.swap_horiz_rounded, color: primary, size: 18),
                  label: Text(
                    'Trocar por similar',
                    style: AppTypography.inter(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
    }
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
                  message: sync.message ?? 'Sincronizando biblioteca...',
                  isDark: isDark,
                  primary: primary,
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
                              _tabIndex == 0 && _selecionado != null
                                  ? 152 +
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
                                  duration: const Duration(milliseconds: 180),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeOutCubic,
                                  child: KeyedSubtree(
                                    key: ValueKey(_tabIndex),
                                    child: _buildTabContent(
                                      context: context,
                                      exercicios: _visibleExercicios(exercicios),
                                      isDark: isDark,
                                      primary: primary,
                                      alreadyInTreinoIds: alreadyInTreinoIds,
                                    ),
                                  ),
                                ),
                                if (_tabIndex == 0 && _selecionado != null) ...[
                                  KeyedSubtree(
                                    key: _prescriptionAnchor,
                                    child: const SizedBox(height: 0),
                                  ),
                                  const SizedBox(height: 18),
                                  _PrescriptionSectionHeader(
                                    isDark: isDark,
                                    primary: primary,
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
                            onEdit: () => setState(() => _tabIndex = 0),
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

class _BibliotecaSyncBanner extends StatelessWidget {
  const _BibliotecaSyncBanner({
    required this.message,
    required this.isDark,
    required this.primary,
  });

  final String message;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.inter(
                  color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatPrescriptionBanner extends StatelessWidget {
  const _RepeatPrescriptionBanner({
    required this.memory,
    required this.isDark,
    required this.primary,
    required this.onApply,
  });

  final ExercisePrescriptionMemory memory;
  final bool isDark;
  final Color primary;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Repetir última prescrição (${memory.summary})',
              style: AppTypography.inter(
                color: mute,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: Text(
              'Aplicar',
              style: AppTypography.inter(
                color: primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlunoEquipmentFilterBanner extends StatelessWidget {
  const _AlunoEquipmentFilterBanner({
    required this.alunoNome,
    required this.equipamentos,
    required this.isDark,
    required this.primary,
    required this.onClear,
  });

  final String alunoNome;
  final Set<Equipamento> equipamentos;
  final bool isDark;
  final Color primary;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final labels =
        equipamentos
            .map((e) => TaxonomyLabels.equipamento[e] ?? e.name)
            .take(3)
            .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Equipamento de $alunoNome: $labels',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mute,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Limpar',
                style: AppTypography.inter(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBibliotecaState extends StatelessWidget {
  const _EmptyBibliotecaState({
    required this.loading,
    required this.isDark,
    required this.primary,
    required this.onImport,
  });

  final bool loading;
  final bool isDark;
  final Color primary;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined, color: primary, size: 42),
            const SizedBox(height: 14),
            Text(
              'Biblioteca padrão pronta para usar',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Importe ~190 exercícios curados (supino, agachamento, remada...) com vídeos padrão. Depois você personaliza com os seus.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: mute,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FxLiquidPrimaryButton(
              label: loading ? 'Importando...' : 'Importar biblioteca',
              icon: Icons.download_rounded,
              onPressed: loading ? null : onImport,
              loading: loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSearchResultTile extends StatelessWidget {
  const _QuickSearchResultTile({
    required this.exercicio,
    required this.alreadyInTreino,
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.highlightQuery = '',
  });

  final Exercicio exercicio;
  final bool alreadyInTreino;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final String highlightQuery;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Row(
            children: [
              ExerciseMediaThumb(
                mediaUrl: exercisePreviewMediaUrl(
                  thumbnailUrl: exercicio.thumbnailUrl,
                  gifUrl: exercicio.gifUrl,
                  videoUrl: exercicio.videoUrl,
                ),
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    highlightedExerciseName(
                      name: exercicio.nomeDisplay,
                      query: highlightQuery,
                      baseStyle: AppTypography.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                      highlightColor: primary,
                    ),
                    if (alreadyInTreino)
                      Text(
                        'Já está neste treino',
                        style: AppTypography.inter(
                          color: mute,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: mute, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MontarComModeloCard extends StatelessWidget {
  const _MontarComModeloCard({
    required this.onTap,
    required this.isDark,
    required this.primary,
  });

  final VoidCallback onTap;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.view_agenda_rounded, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montar com modelo',
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Full body, upper/lower, PPL ou casa — preencha os slots.',
                      style: AppTypography.inter(
                        color: mute,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: mute, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddExerciseErrorBanner extends StatelessWidget {
  const _AddExerciseErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.inter(
                color: EagleTokens.bad,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePrescriptionStrip extends StatelessWidget {
  const _ActivePrescriptionStrip({
    required this.presetId,
    required this.series,
    required this.repeticoes,
    required this.descanso,
    required this.tipoSerie,
    required this.isDark,
    required this.primary,
    required this.onEdit,
  });

  final String presetId;
  final String series;
  final String repeticoes;
  final String descanso;
  final String tipoSerie;
  final bool isDark;
  final Color primary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final preset = workoutBuilderPresetById(presetId);
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final tipoLabel = switch (tipoSerie) {
      'SUPERSET' => ' · Superset',
      'DROPSET' => ' · Drop set',
      _ => '',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(context).bottom > 0 ? 8 : 14,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
            border: Border(top: BorderSide(color: line.withValues(alpha: 0.8))),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescrição ativa: ${preset.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$series×$repeticoes · ${descanso}s descanso$tipoLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Editar',
                style: AppTypography.inter(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyAddExerciseBar extends StatelessWidget {
  const _StickyAddExerciseBar({
    required this.error,
    required this.loading,
    required this.isDark,
    required this.onSubmit,
    required this.onContinue,
  });

  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSubmit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: line.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            _AddExerciseErrorBanner(message: error!),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: loading ? null : onSubmit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(Icons.check_rounded, color: primary, size: 20),
            label: Text(
              'Concluir e voltar ao treino',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                onPrimary: Colors.white,
              ),
            ),
            child: FxLiquidPrimaryButton(
              label: 'Adicionar e continuar',
              icon: Icons.playlist_add_rounded,
              onPressed: loading ? null : onContinue,
              loading: loading,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionSectionHeader extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const _PrescriptionSectionHeader({
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.edit_note_rounded, color: primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prescrição do exercício',
                style: AppTypography.inter(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Ajuste séries, carga, descanso e observações antes de salvar.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  color: mute,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddExerciseTabStrip extends StatelessWidget {
  final int selectedIndex;
  final Color primary;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _AddExerciseTabStrip({
    required this.selectedIndex,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  static const _labels = ['Buscar', 'Explorar'];

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: line.withValues(alpha: 0.72))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _labels[i],
                        style: AppTypography.inter(
                          color: selectedIndex == i ? primary : mute,
                          fontSize: 13,
                          fontWeight:
                              selectedIndex == i
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selectedIndex == i ? 40 : 0,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExercisePickerCard extends StatelessWidget {
  final Exercicio? exercicio;
  final bool isDark;
  final Color primary;
  final int total;
  final bool showPrescriptionHint;
  final bool compactMode;
  final VoidCallback onTap;
  final bool mediaLoading;
  final bool videoExpanded;
  final VoidCallback onToggleVideo;
  final VoidCallback onPreviewVideo;
  final VoidCallback onUploadVideo;
  final VoidCallback onRemoveVideo;
  final VoidCallback onCreate;

  const _ExercisePickerCard({
    required this.exercicio,
    required this.isDark,
    required this.primary,
    required this.total,
    this.showPrescriptionHint = true,
    this.compactMode = false,
    required this.onTap,
    required this.mediaLoading,
    required this.videoExpanded,
    required this.onToggleVideo,
    required this.onPreviewVideo,
    required this.onUploadVideo,
    required this.onRemoveVideo,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final selected = exercicio != null;
    final hasMediaIssue =
        selected && exercicio!.showMediaBadgeInWorkoutList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: fxListCardDecoration(
                    context,
                    accent: selected ? primary : null,
                    selected: selected,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? primary
                                  : primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          selected ? Icons.check_rounded : Icons.search_rounded,
                          color: selected ? Colors.white : primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selected
                                        ? exercicio!.nomeDisplay
                                        : 'Escolher exercício',
                                    maxLines: selected ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      color: ink,
                                      fontSize: 15,
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selected
                                  ? _exerciseMeta(exercicio!)
                                  : '$total exercícios na biblioteca',
                              maxLines: selected ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(
                                color: _metaTextColor(isDark),
                                fontSize: 12,
                                height: 1.18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.expand_more_rounded, color: mute, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: 'Criar exercício personalizado',
              preferBelow: false,
              child: Semantics(
              button: true,
              label: 'Criar exercício personalizado',
              child: InkWell(
              onTap: onCreate,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : EagleTokens.brandSofter,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : primary.withValues(alpha: 0.10),
                  ),
                ),
                child: Icon(Icons.add_rounded, color: primary, size: 26),
              ),
            ),
            ),
            ),
          ],
        ),
        if (!compactMode &&
            (!selected || (showPrescriptionHint && !hasMediaIssue))) ...[
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: fxListCardDecoration(context, accent: primary),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.edit_note_rounded
                      : Icons.auto_awesome_motion_rounded,
                  color: primary,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selected
                        ? 'Revise a prescrição abaixo antes de adicionar.'
                        : 'Busque acima ou explore por movimento/grupo.',
                    style: AppTypography.inter(
                      color: mute,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
        if (selected && !compactMode) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onToggleVideo,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    videoExpanded ? Icons.expand_less : Icons.videocam_outlined,
                    color: mute,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vídeo do exercício (opcional)',
                      style: AppTypography.inter(
                        color: mute,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (videoExpanded) ...[
            const SizedBox(height: 6),
            _ExerciseMediaStatus(
              exercicio: exercicio!,
              isDark: isDark,
              primary: primary,
              mediaLoading: mediaLoading,
              onPreviewVideo: onPreviewVideo,
              onUploadVideo: onUploadVideo,
              onRemoveVideo: onRemoveVideo,
            ),
          ],
        ],
      ],
    );
  }
}

enum _ExerciseMediaAction { preview, upload, remove }

class _ExerciseMediaStatus extends StatelessWidget {
  final Exercicio exercicio;
  final bool isDark;
  final Color primary;
  final bool mediaLoading;
  final VoidCallback onPreviewVideo;
  final VoidCallback onUploadVideo;
  final VoidCallback onRemoveVideo;

  const _ExerciseMediaStatus({
    required this.exercicio,
    required this.isDark,
    required this.primary,
    required this.mediaLoading,
    required this.onPreviewVideo,
    required this.onUploadVideo,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final hasVideo = exercicio.videoUrl?.trim().isNotEmpty == true;
    final statusColor =
        hasVideo
            ? primary
            : isDark
            ? Colors.white.withValues(alpha: 0.68)
            : TokensStrip.textSecondary;
    final statusIcon =
        mediaLoading
            ? Icons.hourglass_empty_rounded
            : hasVideo
            ? Icons.play_circle_fill_rounded
            : Icons.video_call_outlined;
    final statusTitle =
        mediaLoading
            ? 'Processando vídeo'
            : hasVideo
            ? 'Vídeo próprio disponível'
            : 'Sem vídeo próprio';
    final statusSubtitle =
        hasVideo
            ? 'Confira a prévia ou troque a mídia deste exercício.'
            : 'Adicione sua demonstração para revisar antes de prescrever.';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration:
          fxListCardDecoration(
            context,
            accent: hasVideo ? primary : null,
          ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: mute,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasVideo)
            TextButton(
              onPressed: mediaLoading ? null : onPreviewVideo,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('Prévia'),
            ),
          if (hasVideo)
            PopupMenuButton<_ExerciseMediaAction>(
              enabled: !mediaLoading,
              tooltip: 'Ações de vídeo',
              icon: Icon(Icons.more_horiz_rounded, color: mute),
              onSelected: (action) {
                if (action == _ExerciseMediaAction.preview) onPreviewVideo();
                if (action == _ExerciseMediaAction.upload) onUploadVideo();
                if (action == _ExerciseMediaAction.remove) onRemoveVideo();
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: _ExerciseMediaAction.preview,
                      child: Text('Ver prévia'),
                    ),
                    PopupMenuItem(
                      value: _ExerciseMediaAction.upload,
                      child: Text('Trocar vídeo'),
                    ),
                    PopupMenuItem(
                      value: _ExerciseMediaAction.remove,
                      child: Text('Remover vídeo'),
                    ),
                  ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FxLiquidPrimaryButton(
                label: 'Adicionar',
                onPressed: mediaLoading ? null : onUploadVideo,
                loading: mediaLoading,
                expand: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _RemoveExerciseVideoSheet extends StatelessWidget {
  final Exercicio exercicio;

  const _RemoveExerciseVideoSheet({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : TokensStrip.borderDefault,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: EagleTokens.bad.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.videocam_off_outlined,
                      color: EagleTokens.bad,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remover vídeo?',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '"${exercicio.nomeDisplay}" continua na biblioteca. Só a mídia de demonstração será removida.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: EagleTokens.bad,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Remover'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseVideoPreviewSheet extends StatefulWidget {
  final Exercicio exercicio;
  final String url;

  const _ExerciseVideoPreviewSheet({
    required this.exercicio,
    required this.url,
  });

  @override
  State<_ExerciseVideoPreviewSheet> createState() =>
      _ExerciseVideoPreviewSheetState();
}

class _ExerciseVideoPreviewSheetState
    extends State<_ExerciseVideoPreviewSheet> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  int _attempt = 0;
  static const int _maxProcessingAttempts = 10;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_cloudinaryH264VideoUrl(widget.url)),
    );
    _controller = controller;
    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
      });
    }

    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      setState(() => _ready = true);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted || _controller != controller) return;
      _controller = null;
      if (_attempt < _maxProcessingAttempts) {
        _attempt += 1;
        final delaySeconds = (2 + _attempt).clamp(3, 12);
        await Future<void>.delayed(Duration(seconds: delaySeconds));
        if (mounted) await _loadPreview();
        return;
      }
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 10, 16, 16),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : TokensStrip.borderDefault,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: EagleTokens.brandSofter,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      color: primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercicio.nomeDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Confira se a demonstração está correta.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: mute),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.black,
                  child:
                      _failed
                          ? const _VideoPreviewFallback()
                          : !_ready
                          ? const SizedBox(
                            height: 210,
                            child: Center(child: _VideoPreparingPreview()),
                          )
                          : AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                ),
              ),
              if (_ready && !_failed && _controller != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            () => setState(() {
                              _controller!.value.isPlaying
                                  ? _controller!.pause()
                                  : _controller!.play();
                            }),
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _controller!.value.isPlaying
                              ? 'Pausar'
                              : 'Reproduzir',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Está certo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPreparingPreview extends StatelessWidget {
  const _VideoPreparingPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: FxLoading(color: Colors.white, strokeWidth: 2.8),
          ),
          const SizedBox(height: 12),
          Text(
            'Preparando prévia do vídeo...',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Na primeira abertura, o Cloudinary pode levar até um minuto.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _VideoPreviewFallback extends StatelessWidget {
  const _VideoPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_file_rounded, color: Colors.white, size: 34),
            const SizedBox(height: 10),
            Text(
              'Vídeo enviado, mas a prévia ainda não ficou disponível.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tente abrir novamente em instantes. Se persistir, envie um MP4 H.264.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(color: Colors.white70, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

String _cloudinaryH264VideoUrl(String rawUrl) {
  final url = rawUrl.trim();
  const marker = '/video/upload/';
  if (!url.contains(marker)) return url;

  final delivery = url.substring(url.indexOf(marker) + marker.length);
  if (delivery.startsWith('f_mp4') ||
      delivery.startsWith('vc_h264') ||
      delivery.startsWith('vc_auto')) {
    return url;
  }

  return url.replaceFirst(marker, '${marker}f_mp4,vc_h264/');
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercicio> exercicios;
  final Exercicio? selected;
  final Set<int> alreadyInTreinoIds;
  final String initialQuery;

  const _ExercisePickerSheet({
    required this.exercicios,
    required this.selected,
    this.alreadyInTreinoIds = const {},
    this.initialQuery = '',
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final TextEditingController _searchCtrl;
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchCtrl = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final normalized = _query.trim().toLowerCase();
    final filtered = sortExerciciosForPicker(
      normalized.isEmpty
          ? widget.exercicios
          : widget.exercicios.where((exercicio) {
            final haystack =
                '${exercicio.nome} ${exercicio.musculoAlvo ?? ''} '
                        '${exercicio.equipamento ?? ''} ${exercicio.nivel ?? ''}'
                    .toLowerCase();
            return haystack.contains(normalized);
          }),
      alreadyInTreinoIds: widget.alreadyInTreinoIds,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 10, 16, 16),
              decoration: fxListCardDecoration(context, accent: primary),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : TokensStrip.borderDefault,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: EagleTokens.brandSofter,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.fitness_center_rounded, color: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biblioteca de exercícios',
                              style: AppTypography.inter(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${filtered.length} de ${widget.exercicios.length} disponíveis',
                              style: AppTypography.inter(
                                color: mute,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, músculo ou equipamento',
                      prefixIcon: Icon(Icons.search_rounded, color: primary),
                      filled: true,
                      fillColor:
                          isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: line),
                      ),
                      enabledBorder: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: primary, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        filtered.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Text(
                                  'Nenhum exercício encontrado.',
                                  style: AppTypography.inter(
                                    color: mute,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final exercicio = filtered[index];
                                final selected =
                                    widget.selected?.id == exercicio.id;
                                return _ExercisePickerTile(
                                  exercicio: exercicio,
                                  selected: selected,
                                  alreadyInTreino:
                                      widget.alreadyInTreinoIds.contains(
                                        exercicio.id,
                                      ),
                                  primary: primary,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.pop(context, exercicio);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExercisePickerTile extends StatelessWidget {
  final Exercicio exercicio;
  final bool selected;
  final bool alreadyInTreino;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _ExercisePickerTile({
    required this.exercicio,
    required this.selected,
    this.alreadyInTreino = false,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              selected
                  ? EagleTokens.brandSofter
                  : isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected
                    ? primary.withValues(alpha: 0.30)
                    : line.withValues(alpha: 0.9),
          ),
        ),
        child: Row(
          children: [
            ExerciseMediaThumb(
              mediaUrl: exercisePreviewMediaUrl(
                thumbnailUrl: exercicio.thumbnailUrl,
                gifUrl: exercicio.gifUrl,
                videoUrl: exercicio.videoUrl,
              ),
              size: 40,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.nomeDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alreadyInTreino
                        ? 'Já está neste treino · ${_exerciseMeta(exercicio)}'
                        : _exerciseMeta(exercicio),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      color: _metaTextColor(isDark),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mute, size: 20),
          ],
        ),
      ),
    );
  }
}

String _exerciseMeta(Exercicio exercicio) {
  final parts = <String>[
    if (exercicio.grupoMuscularPrimario != null)
      TaxonomyLabels.grupo[exercicio.grupoMuscularPrimario!] ??
          _humanizeMetaToken(exercicio.grupoMuscularPrimario!.backendName),
    if (exercicio.grupoMuscularPrimario == null &&
        exercicio.primaryGroupLabel?.trim().isNotEmpty == true)
      _humanizeMetaToken(exercicio.primaryGroupLabel!),
    if (exercicio.equipamentos.isNotEmpty)
      exercicio.equipamentos
          .take(2)
          .map((e) => TaxonomyLabels.equipamento[e])
          .whereType<String>()
          .join(' / '),
    if (exercicio.equipamentos.isEmpty &&
        exercicio.equipamento?.trim().isNotEmpty == true)
      _humanizeMetaToken(exercicio.equipamento!),
    if (exercicio.dificuldade != null)
      TaxonomyLabels.dificuldade[exercicio.dificuldade!] ??
          _humanizeMetaToken(exercicio.dificuldade!.backendName),
    if (exercicio.dificuldade == null &&
        exercicio.nivel?.trim().isNotEmpty == true)
      _humanizeMetaToken(exercicio.nivel!),
  ];
  final clean = parts.whereType<String>().where((e) => e.isNotEmpty).toList();
  return clean.isEmpty ? 'Sem detalhes' : clean.take(3).join(' · ');
}

Color _metaTextColor(bool isDark) {
  final base =
      isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
  return isDark ? base : Color.lerp(base, TokensStrip.textPrimary, 0.22)!;
}

String _humanizeMetaToken(String value) => displayMetaToken(value);

class _PresetSelector extends StatelessWidget {
  final String selectedId;
  final Color primary;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const _PresetSelector({
    required this.selectedId,
    required this.primary,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = workoutBuilderPresetById(selectedId);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Presets de prescrição',
                style: AppTypography.inter(
                  color: ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                workoutBuilderPresets.map((preset) {
                  final isSelected = preset.id == selectedId;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(preset.label),
                    labelStyle: AppTypography.inter(
                      color: isSelected ? Colors.white : primary,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: primary,
                    backgroundColor: primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: primary.withValues(alpha: isSelected ? 0 : 0.24),
                    ),
                    onSelected: (_) => onSelected(preset.id),
                  );
                }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            selected.summary,
            style: AppTypography.inter(
              color: mute,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SerieTypeSelector extends StatelessWidget {
  final String value;
  final Color primary;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SerieTypeSelector({
    required this.value,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final options = const [
      ('NORMAL', Icons.fitness_center_rounded, 'Normal'),
      ('SUPERSET', Icons.link_rounded, 'Superset'),
      ('DROPSET', Icons.trending_down_rounded, 'Drop set'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de série',
            style: AppTypography.inter(
              color: mute,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.map((option) {
                  final selected = value == option.$1;
                  return ChoiceChip(
                    selected: selected,
                    avatar: Icon(
                      option.$2,
                      size: 16,
                      color: selected ? Colors.white : primary,
                    ),
                    label: Text(option.$3),
                    labelStyle: AppTypography.inter(
                      color: selected ? Colors.white : primary,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: primary,
                    backgroundColor: primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: primary.withValues(alpha: selected ? 0 : 0.25),
                    ),
                    onSelected: (_) => onChanged(option.$1),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ModeHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _ModeHint({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.inter(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Premium composed error state for exercise loading
// ──────────────────────────────────────────────
class _ExercicioErrorState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;

  const _ExercicioErrorState({
    required this.isDark,
    required this.primary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(alpha: isDark ? 0.18 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: EagleTokens.bad,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Erro ao carregar exercícios',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(color: mute, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Centralized premium InputDecoration factory
// ──────────────────────────────────────────────
InputDecoration _fxInputDecoration({
  required String label,
  required bool isDark,
  required Color primary,
  String? helper,
}) {
  final fillColor = isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg;
  final lineColor = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

  return InputDecoration(
    labelText: label,
    helperText: helper,
    filled: true,
    fillColor: fillColor,
    border: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: lineColor),
    ),
    enabledBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: lineColor),
    ),
    focusedBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: primary, width: 1.6),
    ),
    errorBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EagleTokens.bad),
    ),
    focusedErrorBorder: FxInputDeco.outlineBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EagleTokens.bad, width: 1.6),
    ),
  );
}
