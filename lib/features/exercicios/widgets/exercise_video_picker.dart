import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../utils/exercise_video_upload_spec.dart';

/// Câmera ou galeria, com a mesma regra de formato e tamanho do envio no
/// treino. Devolve o caminho do arquivo, ou nulo se desistiu ou foi recusado
/// (o motivo aparece no aviso).
Future<String?> escolherVideoDoExercicio(BuildContext context) async {
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
  if (source == null || !context.mounted) return null;
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
  return file.path;
}
