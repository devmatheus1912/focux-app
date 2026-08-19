import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../exercicios/screens/widgets/exercise_video_preview_sheet.dart';
import '../../exercicios/screens/widgets/exercise_video_spec_tips.dart';
import '../../exercicios/screens/widgets/exercise_video_upload_strip.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/utils/exercise_video_upload_spec.dart';
import '../constants/treinos_layout.dart';
import '../providers/treinos_provider.dart';
import 'treino_home_sheet.dart';

class TreinoPrescriptionVideoBlock extends ConsumerStatefulWidget {
  const TreinoPrescriptionVideoBlock({
    super.key,
    required this.treinoId,
    required this.exercicio,
    required this.isDark,
    required this.busy,
    this.onBusyChanged,
  });

  final int treinoId;
  final Exercicio exercicio;
  final bool isDark;
  final bool busy;
  final ValueChanged<bool>? onBusyChanged;

  @override
  ConsumerState<TreinoPrescriptionVideoBlock> createState() =>
      _TreinoPrescriptionVideoBlockState();
}

class _TreinoPrescriptionVideoBlockState
    extends ConsumerState<TreinoPrescriptionVideoBlock> {
  late Exercicio _exercicio;
  bool _mediaLoading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _exercicio = widget.exercicio;
  }

  @override
  void didUpdateWidget(covariant TreinoPrescriptionVideoBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercicio.id != widget.exercicio.id) {
      _exercicio = widget.exercicio;
    }
  }

  Future<void> _preview() async {
    if (!canPreviewExerciseMedia(_exercicio)) return;
    HapticFeedback.selectionClick();
    await showExerciseMediaPreview(context, exercicio: _exercicio);
  }

  Future<void> _upload() async {
    if (_mediaLoading || widget.busy) return;
    final source = await _showSourceSheet();
    if (source == null || !mounted) return;
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: ExerciseVideoUploadSpec.maxDuration,
    );
    if (file == null || !mounted) return;
    final bytes = await file.length();
    if (!mounted) return;
    final rejection = ExerciseVideoUploadSpec.rejectionFor(
      filename: file.name,
      bytes: bytes,
    );
    if (rejection != null) {
      if (!mounted) return;
      FeedbackHelper.showError(context, rejection);
      return;
    }

    final messenger = FeedbackHelper.messengerOf(context);
    setState(() => _mediaLoading = true);
    widget.onBusyChanged?.call(true);
    FeedbackHelper.showSuccess(
      context,
      'Enviando vídeo de ${_exercicio.nomeDisplay}…',
    );
    try {
      final updated = await ref
          .read(exercicioRepositoryProvider)
          .uploadVideoExercicio(_exercicio.id, file.path);
      AnalyticsService.instance.track(
        'video_personal_upload',
        props: {'exId': _exercicio.id, 'origin': 'treino_prescription'},
      );
      ref.invalidate(treinoProvider(widget.treinoId));
      ref.invalidate(exerciciosProvider);
      if (!mounted) return;
      setState(() => _exercicio = updated);
      messenger.clearSnackBars();
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(
        context,
        'Vídeo no exercício. O aluno vê a mesma gravação no treino.',
      );
    } catch (e) {
      if (!mounted) return;
      messenger.clearSnackBars();
      FeedbackHelper.showError(
        context,
        friendlyError(
          e,
          fallback:
              'Não foi possível enviar o vídeo. Confira o formato (MP4/MOV) e o tamanho (até 120 MB).',
        ),
      );
    } finally {
      if (mounted) setState(() => _mediaLoading = false);
      widget.onBusyChanged?.call(false);
    }
  }

  Future<void> _remove() async {
    if (_mediaLoading || widget.busy) return;
    final confirmed = await _showRemoveSheet();
    if (confirmed != true || !mounted) return;
    setState(() => _mediaLoading = true);
    widget.onBusyChanged?.call(true);
    try {
      final updated = await ref
          .read(exercicioRepositoryProvider)
          .removerVideo(id: _exercicio.id);
      AnalyticsService.instance.track(
        'video_personal_remove',
        props: {'exId': _exercicio.id, 'origin': 'treino_prescription'},
      );
      ref.invalidate(treinoProvider(widget.treinoId));
      ref.invalidate(exerciciosProvider);
      if (!mounted) return;
      setState(() => _exercicio = updated);
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(context, 'Vídeo removido deste exercício.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível remover o vídeo.'),
      );
    } finally {
      if (mounted) setState(() => _mediaLoading = false);
      widget.onBusyChanged?.call(false);
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: fxTransparent,
      barrierColor: heroScrim(0.34),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final chrome = ShellChrome.forDark(isDark);
        final primary = Theme.of(ctx).colorScheme.primary;

        Widget tile({
          required IconData icon,
          required String title,
          required String subtitle,
          required ImageSource source,
        }) {
          return Semantics(
            button: true,
            label: '$title. $subtitle',
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx, source);
              },
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TreinosLayout.touchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: BrandPalette.soft(primary, dark: isDark),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: primary, size: 18),
                      ),
                      SizedBox(width: TokensStrip.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: FocuxHubTypography.cardTitle(
                                color: chrome.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: chrome.mute,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return TreinoHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: TokensStrip.s4),
              TreinoSheetChromeHeader(
                icon: Icons.videocam_rounded,
                title: 'Vídeo do exercício',
                subtitle: 'Filme agora ou escolha um arquivo da galeria.',
                isDark: isDark,
              ),
              SizedBox(height: TokensStrip.s4),
              DecoratedBox(
                decoration: fxListCardDecoration(ctx, accent: primary),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      tile(
                        icon: Icons.photo_camera_rounded,
                        title: 'Filmar agora',
                        subtitle:
                            '${ExerciseVideoUploadSpec.aspectLabel} · '
                            '${ExerciseVideoUploadSpec.idealResolution}',
                        source: ImageSource.camera,
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: chrome.line.withValues(alpha: 0.7),
                      ),
                      tile(
                        icon: Icons.video_library_rounded,
                        title: 'Escolher da galeria',
                        subtitle:
                            '${ExerciseVideoUploadSpec.formatsLabel} · '
                            '${ExerciseVideoUploadSpec.sizeLabel}',
                        source: ImageSource.gallery,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showRemoveSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: fxTransparent,
      barrierColor: heroScrim(0.34),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final chrome = ShellChrome.forDark(isDark);
        return TreinoHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: TokensStrip.s4),
              Text(
                'Remover seu vídeo?',
                style: FocuxHubTypography.pageTitle(ctx, color: chrome.ink),
              ),
              SizedBox(height: TokensStrip.s2),
              Text(
                'A demonstração da biblioteca volta a aparecer, se houver. '
                'O aluno deixa de ver a sua gravação.',
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              SizedBox(height: TokensStrip.s4),
              SizedBox(
                height: TreinosLayout.touchTarget,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: EagleTokens.bad,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Remover vídeo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: TreinosLayout.touchTarget,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(foregroundColor: chrome.mute),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final locked = widget.busy || _mediaLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExerciseVideoUploadStrip(
          exercicio: _exercicio,
          isDark: widget.isDark,
          primary: primary,
          mediaLoading: locked,
          dense: true,
          emptySubtitle: 'Filme a execução para o aluno ver neste treino.',
          onPreview: _preview,
          onUpload: _upload,
          onRemove: _remove,
        ),
        SizedBox(height: TokensStrip.s3),
        ExerciseVideoSpecTips(isDark: widget.isDark),
      ],
    );
  }
}
