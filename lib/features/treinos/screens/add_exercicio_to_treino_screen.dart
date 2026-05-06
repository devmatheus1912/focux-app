import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${exercicio.nome} adicionado.')),
        );
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
    messenger.showSnackBar(
      SnackBar(content: Text('Enviando vídeo de ${exercicio.nome}...')),
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vídeo do exercício atualizado.'),
          backgroundColor: EagleTokens.good,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: EagleTokens.bad,
        ),
      );
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
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vídeo removido do exercício.'),
          backgroundColor: EagleTokens.good,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: EagleTokens.bad,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaLoading = false);
      }
    }
  }

  Widget _buildTabContent({
    required BuildContext context,
    required List<Exercicio> exercicios,
    required bool isDark,
    required Color primary,
  }) {
    switch (_tabIndex) {
      case 1:
        return SizedBox(
          height: 286,
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
          height: 286,
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
                          fontSize: 12,
                          color: mute,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adicionar Exercício',
                        style: TextStyle(
                          fontSize: 28,
                          color: ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
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
                    () => Center(
                      child: CircularProgressIndicator(color: primary),
                    ),
                error:
                    (e, _) => Center(
                      child: Text(
                        'Erro: $e',
                        style: TextStyle(color: EagleTokens.bad),
                      ),
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
                          const SizedBox(height: 18),
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
                                  decoration: InputDecoration(
                                    labelText: 'Séries',
                                    filled: true,
                                    fillColor:
                                        isDark
                                            ? EagleTokens.darkCardHi
                                            : EagleTokens.card,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: ink),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _repCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Repetições',
                                    filled: true,
                                    fillColor:
                                        isDark
                                            ? EagleTokens.darkCardHi
                                            : EagleTokens.card,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(color: ink),
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
                                  decoration: InputDecoration(
                                    labelText: 'Descanso (segundos)',
                                    filled: true,
                                    fillColor:
                                        isDark
                                            ? EagleTokens.darkCardHi
                                            : EagleTokens.card,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: ink),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cargaCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Carga alvo (kg)',
                                    filled: true,
                                    fillColor:
                                        isDark
                                            ? EagleTokens.darkCardHi
                                            : EagleTokens.card,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                      ),
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: TextStyle(color: ink),
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
                              decoration: InputDecoration(
                                labelText: 'Grupo do superset',
                                helperText:
                                    'Use o mesmo numero em exercicios que devem ficar juntos.',
                                filled: true,
                                fillColor:
                                    isDark
                                        ? EagleTokens.darkCardHi
                                        : EagleTokens.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color:
                                        isDark
                                            ? EagleTokens.darkLine
                                            : EagleTokens.line,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color:
                                        isDark
                                            ? EagleTokens.darkLine
                                            : EagleTokens.line,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: ink),
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
                            decoration: InputDecoration(
                              labelText: 'Observacoes de execucao',
                              filled: true,
                              fillColor:
                                  isDark
                                      ? EagleTokens.darkCardHi
                                      : EagleTokens.card,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color:
                                      isDark
                                          ? EagleTokens.darkLine
                                          : EagleTokens.line,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color:
                                      isDark
                                          ? EagleTokens.darkLine
                                          : EagleTokens.line,
                                ),
                              ),
                            ),
                            minLines: 2,
                            maxLines: 4,
                            style: TextStyle(color: ink),
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
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
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
                              child:
                                  _loading
                                      ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        'Adicionar ao Treino',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
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

  static const _labels = ['Buscar', 'Padrão', 'Templates'];

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
                          fontSize: 12,
                          fontWeight:
                              selectedIndex == i
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selectedIndex == i ? 36 : 0,
                        height: 3,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (hasMediaIssue) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EagleTokens.warn.withValues(
                                        alpha: isDark ? 0.16 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Sem mídia',
                                      style: TextStyle(
                                        color: EagleTokens.warn,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selected
                                  ? _exerciseMeta(exercicio!)
                                  : '$total exercícios na biblioteca',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mute,
                                fontSize: 12,
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
                hasMediaIssue
                    ? Icons.videocam_off_outlined
                    : Icons.auto_awesome_motion_rounded,
                color: hasMediaIssue ? EagleTokens.warn : primary,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected
                      ? hasMediaIssue
                          ? 'Pode adicionar. Vídeo ou GIF melhora a orientação depois.'
                          : 'Revise a prescrição abaixo antes de adicionar.'
                      : 'Busque pelo nome ou use padrões/templates para montar rápido.',
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
        if (selected) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ExerciseMediaButton(
                  icon:
                      mediaLoading
                          ? Icons.hourglass_empty_rounded
                          : Icons.video_call_outlined,
                  label:
                      mediaLoading
                          ? 'Processando'
                          : exercicio!.videoUrl?.trim().isNotEmpty == true
                          ? 'Trocar vídeo'
                          : 'Adicionar vídeo',
                  primary: primary,
                  isDark: isDark,
                  onTap: mediaLoading ? null : onUploadVideo,
                ),
              ),
              if (exercicio!.videoUrl?.trim().isNotEmpty == true) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _ExerciseMediaButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remover vídeo',
                    primary: EagleTokens.bad,
                    isDark: isDark,
                    onTap: mediaLoading ? null : onRemoveVideo,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ExerciseMediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final bool isDark;
  final VoidCallback? onTap;

  const _ExerciseMediaButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                isDark
                    ? primary.withValues(alpha: 0.14)
                    : primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primary, size: 17),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    if (exercicio.primaryGroupLabel?.trim().isNotEmpty == true)
      exercicio.primaryGroupLabel!.trim(),
    if (exercicio.equipamento?.trim().isNotEmpty == true)
      exercicio.equipamento!.trim(),
    if (exercicio.nivel?.trim().isNotEmpty == true) exercicio.nivel!.trim(),
  ];
  return parts.isEmpty ? exercicio.mediaTrustLabel : parts.take(3).join(' · ');
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
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
