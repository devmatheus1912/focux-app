import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('conversas da IA cumprem o contrato (13/11)', () {
    final screen = readScreenSourceBundle(
      'lib/features/ia/screens/ia_conversas_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('/ia/copiloto'));
    // Apagar todas pede confirmação; apagar uma tem "Desfazer" (no grupo).
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('IaConversasGrupo'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('TextButton')));
  });
}
