import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../exercicios/screens/widgets/exercise_video_preview_sheet.dart';
import '../../exercicios/screens/widgets/exercise_video_spec_tips.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/utils/exercise_video_upload_spec.dart';
import '../../exercicios/utils/video_oficial.dart';
import '../providers/treinos_provider.dart';
import '../../exercicios/models/exercicio_criado.dart';

class TreinoPrescriptionVideoBlock extends ConsumerStatefulWidget {
  const TreinoPrescriptionVideoBlock({
    super.key,
    required this.treinoId,
    required this.exercicio,
    required this.isDark,
    required this.busy,
    this.onBusyChanged,
    this.onUsarCopia,
  });

  final int treinoId;
  final Exercicio exercicio;
  final bool isDark;
  final bool busy;
  final ValueChanged<bool>? onBusyChanged;

  /// Troca o exercício do item pela cópia recém-criada (id do novo).
  final Future<void> Function(int novoExercicioId)? onUsarCopia;

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
    final hasPersonal = exercicioHasPersonalVideo(_exercicio);
    final confirmed = await showFxConfirmSheet(
      context,
      title: exerciseVideoUploadConfirmTitle(hasVideo: hasPersonal),
      message: exerciseVideoUploadConfirmMessage(),
      confirmLabel: exerciseVideoUploadLabel(hasVideo: hasPersonal),
    );
    if (!confirmed || !mounted) return;
    final source = await showFxInsetPickerSheet<ImageSource>(
      context,
      title: exerciseVideoSourceSheetTitle(),
      subtitle: exerciseVideoSourceSheetSubtitle(),
      headerIcon: Icons.videocam_rounded,
      items: [
        FxInsetPickerSheetItem(
          value: ImageSource.camera,
          label: exerciseVideoSourceCameraLabel(),
          subtitle:
              '${ExerciseVideoUploadSpec.aspectLabel} · '
              '${ExerciseVideoUploadSpec.idealResolution}',
          icon: Icons.photo_camera_rounded,
        ),
        FxInsetPickerSheetItem(
          value: ImageSource.gallery,
          label: exerciseVideoSourceGalleryLabel(),
          subtitle:
              '${ExerciseVideoUploadSpec.formatsLabel} · '
              '${ExerciseVideoUploadSpec.sizeLabel}',
          icon: Icons.video_library_rounded,
        ),
      ],
    );
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
    final confirmed = await showFxConfirmSheet(
      context,
      title: exerciseVideoRemoveConfirmTitle(),
      message: exerciseVideoRemoveConfirmMessage(),
      confirmLabel: exerciseVideoRemoveLabel(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
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
      FeedbackHelper.showSuccess(context, exerciseVideoRemoveSuccess());
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

  Future<void> _criarMeu() async {
    HapticFeedback.selectionClick();
    final criado = await context.push<ExercicioCriado>(
      '/exercicios/novo?origem=troca',
      extra: _exercicio,
    );
    final criadoId =
        criado?.destino == ExercicioCriadoDestino.usarNoLugar
            ? criado?.id
            : null;
    final usar = widget.onUsarCopia;
    if (criadoId == null || usar == null || !mounted) return;
    final trocar = await showFxConfirmSheet(
      context,
      title: 'Usar no treino?',
      message:
          'Seu exercício foi criado. Trocar "${_exercicio.nomeDisplay}" '
          'pelo seu neste treino? A prescrição é mantida.',
      confirmLabel: 'Usar o meu',
    );
    if (!trocar || !mounted) return;
    await usar(criadoId);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, widget.isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final locked = widget.busy || _mediaLoading;
    final hasPersonal = exercicioHasPersonalVideo(_exercicio);
    final canPreview = canPreviewExerciseMedia(_exercicio);
    final editavel = videoEditavel(_exercicio);
    final title =
        locked
            ? 'Enviando…'
            : hasPersonal
            ? 'Seu vídeo'
            : 'Demonstração';
    final caption =
        locked
            ? 'Não feche o app enquanto o envio termina.'
            : editavel
            ? (hasPersonal
                ? 'Revise a gravação ou envie outra.'
                : 'Envie o seu vídeo para o aluno ver a sua técnica.')
            : 'O vídeo da Focux é fixo. Para usar o seu, crie o seu exercício.';

    return Semantics(
      container: true,
      liveRegion: locked,
      label: '$title. $caption',
      child: FxSettingsGroup(
        header: 'Vídeo',
        caption: caption,
        accent: primary,
        helpTooltip: editavel ? 'Como filmar' : null,
        onHelpTap: editavel ? () => ExerciseVideoSpecTips.open(context) : null,
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
          else ...[
            if (canPreview)
              FxSettingsTile(
                icon: Icons.play_circle_outline_rounded,
                accent: brand,
                label: title,
                value: exerciseVideoPreviewLabel(hasPersonal: hasPersonal),
                picker: true,
                showDivider: true,
                onTap: _preview,
              ),
            if (editavel)
              FxSettingsTile(
                icon: Icons.videocam_outlined,
                accent: brand,
                label: exerciseVideoUploadLabel(hasVideo: hasPersonal),
                value: '',
                picker: true,
                showDivider: hasPersonal,
                onTap: _upload,
              )
            else
              FxSettingsTile(
                icon: Icons.add_circle_outline_rounded,
                accent: brand,
                label: 'Criar meu exercício com meu vídeo',
                value: '',
                picker: true,
                showDivider: false,
                onTap: _criarMeu,
              ),
            if (editavel && hasPersonal)
              FxSettingsTile(
                icon: Icons.delete_outline_rounded,
                label: exerciseVideoRemoveLabel(),
                value: '',
                danger: true,
                showDivider: false,
                onTap: _remove,
              ),
          ],
        ],
      ),
    );
  }
}
