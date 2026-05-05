import 'package:image_picker/image_picker.dart';

import 'exercicio_repository.dart';

class ExercicioVideoUploader {
  ExercicioVideoUploader(this._repository, {ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ExercicioRepository _repository;
  final ImagePicker _picker;

  Future<Exercicio?> pickAndUpload(int exercicioId) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    return _repository.uploadVideoExercicio(exercicioId, file.path);
  }
}
