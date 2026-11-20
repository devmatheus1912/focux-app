import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../utils/exercise_video_upload_spec.dart';
import '../../../core/theme/fx_icons.dart';

/// Vídeo escolhido e já conferido (formato, tamanho e duração).
class VideoDoExercicio {
  const VideoDoExercicio({
    required this.path,
    required this.bytes,
    this.duracao,
  });

  final String path;
  final int bytes;

  /// Nula quando o aparelho não conseguiu ler a duração.
  final Duration? duracao;

  String get resumo => exerciseVideoResumo(duracao: duracao, bytes: bytes);
}

/// Escolhe o vídeo. [aoPreparar] roda assim que a origem é escolhida: na
/// galeria o sistema copia o arquivo antes de devolvê-lo, e vídeo longo leva
/// segundos; quem chama mostra "Preparando vídeo…" até o retorno.
typedef EscolherVideoDoExercicio =
    Future<VideoDoExercicio?> Function(
      BuildContext context, {
      VoidCallback? aoPreparar,
    });

/// Trocável em teste (seletor nativo não roda no `flutter test`).
final escolherVideoDoExercicioProvider = Provider<EscolherVideoDoExercicio>(
  (ref) => escolherVideoDoExercicio,
);

/// Câmera ou galeria, com a mesma regra de formato, tamanho e duração do
/// envio no treino. Devolve nulo se desistiu ou foi recusado (o motivo
/// aparece no aviso).
Future<VideoDoExercicio?> escolherVideoDoExercicio(
  BuildContext context, {
  VoidCallback? aoPreparar,
}) async {
  final source = await showFxInsetPickerSheet<ImageSource>(
    context,
    title: exerciseVideoSourceSheetTitle(),
    subtitle: exerciseVideoSourceSheetSubtitle(),
    headerIcon: FxIcons.video,
    items: [
      FxInsetPickerSheetItem(
        value: ImageSource.camera,
        label: exerciseVideoSourceCameraLabel(),
        subtitle:
            '${ExerciseVideoUploadSpec.aspectLabel} · '
            '${ExerciseVideoUploadSpec.idealResolution}',
        icon: FxIcons.camera,
      ),
      FxInsetPickerSheetItem(
        value: ImageSource.gallery,
        label: exerciseVideoSourceGalleryLabel(),
        subtitle:
            '${ExerciseVideoUploadSpec.formatsLabel} · '
            '${ExerciseVideoUploadSpec.durationLabel}',
        icon: FxIcons.videos,
      ),
    ],
  );
  if (source == null || !context.mounted) return null;
  aoPreparar?.call();
  // `maxDuration` só limita a gravação; da galeria vem qualquer duração.
  final file = await ImagePicker().pickVideo(
    source: source,
    maxDuration: ExerciseVideoUploadSpec.maxDuration,
  );
  if (file == null || !context.mounted) return null;
  final bytes = await file.length();
  final rejection = ExerciseVideoUploadSpec.rejectionFor(
    filename: file.name,
    bytes: bytes,
  );
  if (rejection != null) {
    if (context.mounted) FeedbackHelper.showError(context, rejection);
    return null;
  }
  final duracao = await lerDuracaoDoVideo(file.path);
  final longo = ExerciseVideoUploadSpec.rejectionForDuration(duracao);
  if (longo != null) {
    if (context.mounted) FeedbackHelper.showError(context, longo);
    return null;
  }
  return VideoDoExercicio(path: file.path, bytes: bytes, duracao: duracao);
}

/// Lê a duração sem tocar o vídeo. Falha vira nulo (não recusa por isso).
Future<Duration?> lerDuracaoDoVideo(String path) async {
  final controller = VideoPlayerController.file(File(path));
  try {
    await controller.initialize().timeout(const Duration(seconds: 10));
    final d = controller.value.duration;
    return d > Duration.zero ? d : null;
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}
