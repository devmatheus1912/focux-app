class PickedExerciseMediaFile {
  final String name;
  final String content;

  const PickedExerciseMediaFile({
    required this.name,
    required this.content,
  });
}

Future<PickedExerciseMediaFile?> pickExerciseMediaFile() async => null;

Future<bool> downloadExerciseMediaTemplate({
  required String filename,
  required String content,
}) async =>
    false;
