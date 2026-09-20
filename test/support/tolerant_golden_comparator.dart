import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aceita ruído de AA/fonte entre runners Linux (≤ [maxDiffPercent] %).
///
/// Chamar em `setUpAll` de cada arquivo golden — o `basedir` do
/// [LocalFileComparator] já aponta pro diretório do teste.
void useTolerantGoldens({double maxDiffPercent = 0.5}) {
  final current = goldenFileComparator;
  if (current is! LocalFileComparator) return;
  goldenFileComparator = TolerantGoldenComparator(
    current.basedir,
    maxDiffPercent: maxDiffPercent,
  );
}

class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.basedir, {required this.maxDiffPercent});

  final double maxDiffPercent;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    final withinTolerance =
        !result.passed && result.diffPercent <= maxDiffPercent;
    if (result.passed || withinTolerance) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
