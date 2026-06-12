import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/clean_code/focux_clean_code.dart';

void main() {
  test('FocuxCleanCode catalog defines composition and forbidden patterns', () {
    expect(FocuxCleanCode.version, isNotEmpty);
    expect(FocuxCleanCode.mixedResponsibilityLineThreshold, greaterThan(0));
    expect(FocuxCleanCode.hubCompositionPatterns, isNotEmpty);
    expect(FocuxCleanCode.forbiddenHubPatterns, contains('Map<String, dynamic>'));
    expect(FocuxCleanCode.automatedGates, isNotEmpty);
  });

  test('typed boundary modules exist', () {
    expect(FocuxCleanCode.coreSources, hasLength(5));
    expect(
      FocuxCleanCode.coreSources,
      contains('lib/features/ia/models/ia_copilot_proxima_acao.dart'),
    );
  });
}
