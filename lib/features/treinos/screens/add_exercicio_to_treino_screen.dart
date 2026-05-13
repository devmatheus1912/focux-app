import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../exercicios/screens/widgets/padrao_movimento_grid.dart';
import '../../exercicios/screens/widgets/template_split_picker.dart';
import '../data/workout_builder_preset.dart';
import '../providers/treinos_provider.dart';

class AddExercicioToTreinoScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const AddExercicioToTreinoScreen({super.key, required this.treinoId});

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

  void _applyPreset(String id) {
    final preset = workoutBuilderPresetById(id);
    setState(() {
      _presetId = id;
      _seriesCtrl.text = preset.series.toString();
      _repCtrl.text = preset.repeticoes;
      _descansoCtrl.text = preset.descansoSegundos.toString();
      _tipoSerie = preset.tipoSerie;
      _observacoesCtrl.text = preset.observacoes;
      if (preset.grupoSuperset != null) {
        _grupoSupersetCtrl.text = preset.grupoSuperset.toString();
      }
    });
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
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            _selecionado!.id,
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
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
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

  Future<void> _adicionarRapido(Exercicio exercicio) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicio.id,
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
      AnalyticsService.instance.track(
        'quick_add_padrao',
        props: {'exId': exercicio.id, 'treinoId': widget.treinoId},
      );
      if (mounted) {
        FeedbackHelper.showSuccess(context, '${exercicio.nome} adicionado.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao adicionar exercicio.';
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

  Future<void> _openExercisePicker(List<Exercicio> exercicios) async {
    HapticFeedback.selectionClick();
    final selected = await showModalBottomSheet<Exercicio>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      builder:
          (sheetContext) => _ExercisePickerSheet(
            exercicios: exercicios,
            selected: _selecionado,
          ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selecionado = selected;
        _error = null;
      });
    }
  }

  Future<void> _uploadSelectedExerciseVideo() async {
    final exercicio = _selecionado;
    if (exercicio == null || _mediaLoading) return;
    final file = await _videoPicker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _mediaLoading = true);
    FeedbackHelper.showSuccess(context, 'Enviando vídeo de ${exercicio.nome}...');
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
    final videoUrl = exercicio?.videoUrl?.trim();
    if (exercicio == null || videoUrl == null || videoUrl.isEmpty) return;
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      isScrollControlled: true,
      builder:
          (_) =>
              _ExerciseVideoPreviewSheet(exercicio: exercicio, url: videoUrl),
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required List<Exercicio> exercicios,
    required bool isDark,
    required Color primary,
  }) {
    final browseHeight =
        (MediaQuery.sizeOf(context).height - 280)
            .clamp(430.0, 620.0)
            .toDouble();
    switch (_tabIndex) {
      case 1:
        return SizedBox(
          height: browseHeight,
          child: PadraoMovimentoGrid(
            onAdicionar:
                (exercicio) => setState(() {
                  _selecionado = exercicio;
                  _tabIndex = 0;
                  _error = null;
                }),
          ),
        );
      case 2:
        return SizedBox(
          height: browseHeight,
          child: TemplateSplitPicker(
            onAdicionar: (exercicio) async {
              await _adicionarRapido(exercicio);
              AnalyticsService.instance.track(
                'template_uso',
                props: {'treinoId': widget.treinoId, 'exId': exercicio.id},
              );
            },
          ),
        );
      default:
        return _ExercisePickerCard(
          exercicio: _selecionado,
          isDark: isDark,
          primary: primary,
          total: exercicios.length,
          onTap: () => _openExercisePicker(exercicios),
          mediaLoading: _mediaLoading,
          onPreviewVideo: _previewSelectedExerciseVideo,
          onUploadVideo: _uploadSelectedExerciseVideo,
          onRemoveVideo: _removeSelectedExerciseVideo,
          onCreate: () async {
            final criado = await context.push<bool>('/exercicios/novo');
            if (criado == true) {
              ref.invalidate(exerciciosProvider);
            }
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(exerciciosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOVO ITEM',
                        style: TextStyle(
                          fontSize: 11,
                          color: mute,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicionar Exercício',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          color: ink,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: mute),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
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
                    (exercicios) => SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
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
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            child: KeyedSubtree(
                              key: ValueKey(_tabIndex),
                              child: _buildTabContent(
                                context: context,
                                exercicios: exercicios,
                                isDark: isDark,
                                primary: primary,
                              ),
                            ),
                          ),
                          if (_tabIndex == 0 && _selecionado != null) ...[
                            const SizedBox(height: 18),
                            _PrescriptionSectionHeader(
                              isDark: isDark,
                              primary: primary,
                            ),
                            const SizedBox(height: 12),
                            _PresetSelector(
                              selectedId: _presetId,
                              primary: primary,
                              isDark: isDark,
                              onSelected: _applyPreset,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _seriesCtrl,
                                    decoration: _fxInputDecoration(
                                      label: 'Séries',
                                      isDark: isDark,
                                      primary: primary,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _repCtrl,
                                    decoration: _fxInputDecoration(
                                      label: 'Repetições',
                                      isDark: isDark,
                                      primary: primary,
                                    ),
                                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _descansoCtrl,
                                    decoration: _fxInputDecoration(
                                      label: 'Descanso (segundos)',
                                      isDark: isDark,
                                      primary: primary,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cargaCtrl,
                                    decoration: _fxInputDecoration(
                                      label: 'Carga alvo (kg)',
                                      isDark: isDark,
                                      primary: primary,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SerieTypeSelector(
                              value: _tipoSerie,
                              primary: primary,
                              isDark: isDark,
                              onChanged:
                                  (value) => setState(() => _tipoSerie = value),
                            ),
                            if (_tipoSerie == 'SUPERSET') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _grupoSupersetCtrl,
                                decoration: _fxInputDecoration(
                                  label: 'Grupo do superset',
                                  helper: 'Use o mesmo numero em exercicios que devem ficar juntos.',
                                  isDark: isDark,
                                  primary: primary,
                                ),
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                              ),
                            ],
                            if (_tipoSerie == 'DROPSET') ...[
                              const SizedBox(height: 12),
                              _ModeHint(
                                icon: Icons.trending_down_rounded,
                                text:
                                    'Drop set: registre reducoes de carga nas observacoes ou no acompanhamento por serie.',
                                color: EagleTokens.warn,
                                isDark: isDark,
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _observacoesCtrl,
                              decoration: _fxInputDecoration(
                                label: 'Observações de execução',
                                isDark: isDark,
                                primary: primary,
                              ),
                              minLines: 2,
                              maxLines: 4,
                              style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: EagleTokens.bad.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: EagleTokens.bad.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: EagleTokens.bad,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: EagleTokens.bad,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _submit,
                                icon: _loading
                                    ? const SizedBox.shrink()
                                    : const Icon(Icons.add_rounded, size: 20),
                                label:
                                    _loading
                                        ? SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        )
                                        : const Text(
                                          'Adicionar ao Treino',
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
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
                style: TextStyle(
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
                style: TextStyle(
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

  static const _labels = ['Buscar', 'Categorias', 'Modelos'];

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

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
                        style: TextStyle(
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
  final VoidCallback onTap;
  final bool mediaLoading;
  final VoidCallback onPreviewVideo;
  final VoidCallback onUploadVideo;
  final VoidCallback onRemoveVideo;
  final VoidCallback onCreate;

  const _ExercisePickerCard({
    required this.exercicio,
    required this.isDark,
    required this.primary,
    required this.total,
    required this.onTap,
    required this.mediaLoading,
    required this.onPreviewVideo,
    required this.onUploadVideo,
    required this.onRemoveVideo,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final selected = exercicio != null;
    final hasMediaIssue = selected && exercicio!.mediaTrustLevel != 'READY';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? EagleTokens.darkCardHi
                            : selected
                            ? EagleTokens.brandSofter
                            : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          selected
                              ? primary.withValues(alpha: 0.28)
                              : line.withValues(alpha: 0.95),
                    ),
                    boxShadow:
                        isDark
                            ? null
                            : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.045),
                                blurRadius: 22,
                                offset: const Offset(0, 12),
                              ),
                            ],
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
                                        ? exercicio!.nome
                                        : 'Escolher exercício',
                                    maxLines: selected ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
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
                              style: TextStyle(
                                color: mute,
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
            InkWell(
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
          ],
        ),
        if (!selected || !hasMediaIssue) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.035)
                      : EagleTokens.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line.withValues(alpha: 0.76)),
            ),
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
                        : 'Busque pelo nome ou use Categorias e Modelos para montar rápido.',
                    style: TextStyle(
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
        ],
        if (selected) ...[
          const SizedBox(height: 10),
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
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final hasVideo = exercicio.videoUrl?.trim().isNotEmpty == true;
    final statusColor =
        hasVideo
            ? primary
            : isDark
            ? Colors.white.withValues(alpha: 0.68)
            : EagleTokens.inkMute;
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
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.035)
                : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line.withValues(alpha: 0.72)),
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
                  style: TextStyle(
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
                  style: TextStyle(
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
                textStyle: const TextStyle(
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
              child: FilledButton(
                onPressed: mediaLoading ? null : onUploadVideo,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(86, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text('Adicionar'),
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : EagleTokens.lineSoft,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
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
                          : EagleTokens.line,
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
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '"${exercicio.nome}" continua na biblioteca. Só a mídia de demonstração será removida.',
                          style: TextStyle(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: line.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.16),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
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
                            : EagleTokens.line,
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
                    child: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: EagleTokens.brand,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercicio.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Confira se a demonstração está correta.',
                          style: TextStyle(
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
                          backgroundColor: EagleTokens.brand,
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
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.8,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Preparando prévia do vídeo...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text(
            'Na primeira abertura, o Cloudinary pode levar até um minuto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
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
    return const SizedBox(
      height: 210,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_file_rounded, color: Colors.white, size: 34),
            SizedBox(height: 10),
            Text(
              'Vídeo enviado, mas a prévia ainda não ficou disponível.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Tente abrir novamente em instantes. Se persistir, envie um MP4 H.264.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
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

  const _ExercisePickerSheet({
    required this.exercicios,
    required this.selected,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final bottom = MediaQuery.of(context).padding.bottom;
    final normalized = _query.trim().toLowerCase();
    final filtered =
        normalized.isEmpty
            ? widget.exercicios
            : widget.exercicios.where((exercicio) {
              final haystack =
                  '${exercicio.nome} ${exercicio.musculoAlvo ?? ''} '
                          '${exercicio.equipamento ?? ''} ${exercicio.nivel ?? ''}'
                      .toLowerCase();
              return haystack.contains(normalized);
            }).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, bottom + 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : EagleTokens.lineSoft,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.16),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
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
                          : EagleTokens.line,
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
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${filtered.length} de ${widget.exercicios.length} disponíveis',
                          style: TextStyle(
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
                  fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: primary, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child:
                    filtered.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              'Nenhum exercício encontrado.',
                              style: TextStyle(
                                color: mute,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        : ListView.separated(
                          shrinkWrap: true,
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
  }
}

class _ExercisePickerTile extends StatelessWidget {
  final Exercicio exercicio;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _ExercisePickerTile({
    required this.exercicio,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? primary : primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? Icons.check_rounded : _trustIcon(exercicio),
                color:
                    selected ? Colors.white : _trustColor(exercicio, primary),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _exerciseMeta(exercicio),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mute,
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
  return clean.isEmpty ? exercicio.mediaTrustLabel : clean.take(3).join(' · ');
}

String _humanizeMetaToken(String value) {
  final normalized = value.trim().replaceAll('_', ' ').toLowerCase();
  if (normalized.isEmpty) return normalized;
  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final card = isDark ? EagleTokens.darkCardHi : EagleTokens.card;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Presets de prescrição',
                style: TextStyle(
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
                    labelStyle: TextStyle(
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
            style: TextStyle(
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

Color _trustColor(Exercicio exercicio, Color primary) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' => exercicio.isPersonalUpload ? primary : EagleTokens.good,
    'NO_VIDEO' => EagleTokens.bad,
    _ => EagleTokens.warn,
  };
}

IconData _trustIcon(Exercicio exercicio) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' =>
      exercicio.isPersonalUpload
          ? Icons.workspace_premium_rounded
          : Icons.verified_rounded,
    'NO_VIDEO' => Icons.videocam_off_outlined,
    _ => Icons.rate_review_outlined,
  };
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
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final card = isDark ? EagleTokens.darkCardHi : EagleTokens.card;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final options = const [
      ('NORMAL', Icons.fitness_center_rounded, 'Normal'),
      ('SUPERSET', Icons.link_rounded, 'Superset'),
      ('DROPSET', Icons.trending_down_rounded, 'Drop set'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de serie',
            style: TextStyle(
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
                    labelStyle: TextStyle(
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
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
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
              style: TextStyle(
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

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
              style: GoogleFonts.outfit(
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
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
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
  final fillColor = isDark ? EagleTokens.darkCardHi : EagleTokens.card;
  final lineColor = isDark ? EagleTokens.darkLine : EagleTokens.line;

  return InputDecoration(
    labelText: label,
    helperText: helper,
    filled: true,
    fillColor: fillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: lineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: lineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EagleTokens.bad),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EagleTokens.bad, width: 1.6),
    ),
  );
}
