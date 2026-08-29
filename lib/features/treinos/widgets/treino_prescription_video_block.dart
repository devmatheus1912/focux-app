import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../exercicios/screens/widgets/exercise_video_preview_sheet.dart';
import '../../exercicios/screens/widgets/exercise_video_spec_tips.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/utils/exercise_video_upload_spec.dart';
import '../constants/treinos_layout.dart';
import '../providers/treinos_provider.dart';
import 'treino_home_sheet.dart';
import 'treino_inset_sheet.dart';

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
    return showFxHomeSheet<ImageSource>(
      context,
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
              FxHomeSheetHandle(isDark: isDark),
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
    return showFxHomeSheet<bool>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return TreinoInsetConfirmSheet(
          isDark: isDark,
          headerIcon: Icons.delete_outline_rounded,
          title: 'Remover seu vídeo?',
          message:
              'A demonstração da biblioteca volta a aparecer, se houver. '
              'O aluno deixa de ver a sua gravação.',
          confirmLabel: 'Remover vídeo',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(widget.isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final locked = widget.busy || _mediaLoading;
    final hasPersonal = exercicioHasPersonalVideo(_exercicio);
    final canPreview = canPreviewExerciseMedia(_exercicio);
    final title =
        locked
            ? 'Enviando…'
            : hasPersonal
            ? 'Seu vídeo'
            : 'Demonstração';
    final caption =
        locked
            ? 'Não feche o app enquanto o envio termina.'
            : hasPersonal
            ? 'Toque em Ver para revisar ou Trocar para enviar outro.'
            : 'Demo da biblioteca ou envie o seu.';

    return Semantics(
      container: true,
      liveRegion: locked,
      label: '$title. $caption',
      child: FxSettingsGroup(
        header: 'Vídeo',
        caption: caption,
        accent: primary,
        helpTooltip: 'Como filmar',
        onHelpTap: () => ExerciseVideoSpecTips.open(context),
        children: [
          if (locked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: FxSettingsLayout.iconSize,
                        color: brand,
                      ),
                      SizedBox(width: FxSettingsLayout.iconGap),
                      Expanded(
                        child: Text(
                          title,
                          style: FxSettingsLayout.rowLabel(color: chrome.ink),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: TokensStrip.s3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      color: primary,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FxSettingsLayout.rowMinHeight,
              ),
              child: Row(
                children: [
                  Icon(
                    hasPersonal
                        ? Icons.play_circle_fill_rounded
                        : Icons.videocam_outlined,
                    size: FxSettingsLayout.iconSize,
                    color: brand,
                  ),
                  SizedBox(width: FxSettingsLayout.iconGap),
                  Expanded(
                    child: Text(
                      title,
                      style: FxSettingsLayout.rowLabel(color: chrome.ink),
                    ),
                  ),
                  if (canPreview)
                    TextButton(
                      onPressed: _preview,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          FxHomeSheetChrome.touchTarget,
                          FxHomeSheetChrome.touchTarget,
                        ),
                        foregroundColor: primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: Text(hasPersonal ? 'Ver' : 'Demo'),
                    ),
                  TextButton(
                    onPressed: _upload,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        FxHomeSheetChrome.touchTarget,
                        FxHomeSheetChrome.touchTarget,
                      ),
                      foregroundColor: primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: Text(hasPersonal ? 'Trocar' : 'Enviar'),
                  ),
                  if (hasPersonal)
                    TextButton(
                      onPressed: _remove,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          FxHomeSheetChrome.touchTarget,
                          FxHomeSheetChrome.touchTarget,
                        ),
                        foregroundColor: chrome.mute,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Remover'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
