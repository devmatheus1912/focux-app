// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

class PickedExerciseMediaFile {
  final String name;
  final String content;

  const PickedExerciseMediaFile({
    required this.name,
    required this.content,
  });
}

Future<PickedExerciseMediaFile?> pickExerciseMediaFile() async {
  final input =
      html.FileUploadInputElement()
        ..accept = '.csv,.json,text/csv,application/json'
        ..multiple = false;
  input.click();

  await input.onChange.first;
  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) return null;

  final reader = html.FileReader();
  final completer = Completer<String>();
  reader.onLoad.first.then((_) {
    completer.complete(reader.result?.toString() ?? '');
  });
  reader.onError.first.then((_) {
    completer.completeError(Exception('Nao foi possivel ler o arquivo'));
  });
  reader.readAsText(file);

  return PickedExerciseMediaFile(
    name: file.name,
    content: await completer.future,
  );
}

Future<bool> downloadExerciseMediaTemplate({
  required String filename,
  required String content,
}) async {
  final blob = html.Blob([content], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    html.AnchorElement(href: url)
      ..download = filename
      ..click();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
  return true;
}
