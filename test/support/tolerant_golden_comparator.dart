import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aceita ruído de AA/fonte entre runners Linux (≤ [maxDiffPercent] %).
///
/// Delega path/IO ao [LocalFileComparator] original — não recria basedir.
void useTolerantGoldens({double maxDiffPercent = 0.5}) {
  final current = goldenFileComparator;
  if (current is TolerantGoldenComparator) return;
  if (current is! LocalFileComparator) return;
  goldenFileComparator = TolerantGoldenComparator(
    current,
    maxDiffPercent: maxDiffPercent,
  );
}

class TolerantGoldenComparator implements GoldenFileComparator {
  TolerantGoldenComparator(this._inner, {required this.maxDiffPercent});

  final LocalFileComparator _inner;
  final double maxDiffPercent;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await _inner.getGoldenBytes(golden),
    );

    final withinTolerance =
        !result.passed && result.diffPercent <= maxDiffPercent;
    if (result.passed || withinTolerance) {
      result.dispose();
      return true;
    }

    final error = await _inner.generateFailureOutput(
      result,
      golden,
      _inner.basedir,
    );
    result.dispose();
    throw FlutterError(error);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      _inner.update(golden, imageBytes);

  @override
  Uri getTestUri(Uri key, int? version) => _inner.getTestUri(key, version);
}
