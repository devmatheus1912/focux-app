import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// OCR on-device — sem custo de API na leitura de prints.
class MigracaoOcrService {
  MigracaoOcrService._();

  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static bool get disponivel => !kIsWeb;

  static Future<String> extrairTextoDeArquivo(String path) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR disponível apenas no app mobile.');
    }
    final input = InputImage.fromFilePath(path);
    final result = await _recognizer.processImage(input);
    return result.text.trim();
  }

  static Future<String> extrairTextoDeBytes(
    Uint8List bytes, {
    required String filename,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR disponível apenas no app mobile.');
    }
    final dir = await getTemporaryDirectory();
    final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final file = File('${dir.path}/migracao_ocr_$safeName');
    await file.writeAsBytes(bytes, flush: true);
    try {
      return await extrairTextoDeArquivo(file.path);
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
