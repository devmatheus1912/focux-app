// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';

/// Downloads curated Rive community assets (CC BY) bundled with the app.
/// Run: dart run tool/download_rive_assets.dart
Future<void> main() async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    headers: {'User-Agent': 'FocuxApp/1.1 asset-fetch'},
  ));

  const assets = <String, String>{
    'confetti_success.riv':
        'https://public.rive.app/community/runtime-files/7184-13803-success-confetti-animation.riv',
    'confetti_burst.riv':
        'https://public.rive.app/community/runtime-files/15318-28910-confetti-animation.riv',
    'star_sparkle.riv':
        'https://public.rive.app/community/runtime-files/2195-4346-avatar-pack-use-case.riv',
    'cdn_heart.riv': 'https://cdn.rive.app/animations/heart.riv',
  };

  final dir = Directory('assets/animations');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  for (final entry in assets.entries) {
    final path = '${dir.path}/${entry.key}';
    print('Downloading ${entry.key}...');
    try {
      await dio.download(entry.value, path);
      final size = File(path).lengthSync();
      print(size > 512 ? '  OK ($size bytes)' : '  WARN: file too small');
    } catch (e) {
      print('  FAIL: $e');
    }
  }
  print('Done.');
}
