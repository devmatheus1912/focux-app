import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('migracao magica cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/growth/screens/migracao_magica_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('UpgradePromptSheet'));
    expect(screen, isNot(contains('showDialog')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('migracaoIniciarLabel'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('migracaoEtapaLabel'));
    expect(screen, contains('FxWizardStickyBar'));
    expect(screen, contains('FxWizardStepDots'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('MigracaoMagicaDraftCache'));
    expect(screen, contains('MigracaoEtapa.acesso'));
    expect(screen, contains('migracaoVagasHint'));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, isNot(contains('FeatureGate')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  // M1 — múltiplos prints: galeria usa pickMultiImage
  test('galeria usa pickMultiImage para suportar múltiplas fotos', () {
    final actions = readScreenSourceBundle(
        'lib/features/growth/screens/migracao_magica_screen_actions.part.dart');
    expect(actions, contains('pickMultiImage'));
    expect(actions, contains('_processarMultiplasImagens'));
    // câmera ainda usa pickImage (1 foto)
    expect(actions, contains('pickImage'));
  });

  // M3 — PDF: aceito no file picker e processado via OCR
  test('file picker aceita PDF e há handler _processarPdf', () {
    final actions = readScreenSourceBundle(
        'lib/features/growth/screens/migracao_magica_screen_actions.part.dart');
    expect(actions, contains("'pdf'"));
    expect(actions, contains('_isPdfFilename'));
    expect(actions, contains('_processarPdf'));
    expect(actions, contains('PdfDocument'));
  });

  // C1 — botão de envio em lote com guia WhatsApp
  test('tela de acesso tem botão de envio em lote e guia de transmissão', () {
    final build = readScreenSourceBundle(
        'lib/features/growth/screens/migracao_magica_screen_build.part.dart');
    expect(build, contains('_MigracaoEnviarTodosButton'));
    expect(build, contains('transmissão'));
    expect(build, contains('whatsapp://'));
    expect(build, contains('_PassoTransmissao'));
  });

  // M4 — dica de orientação no sheet de foto
  test('sheet de foto orienta tirar foto só da lista', () {
    final actions = readScreenSourceBundle(
        'lib/features/growth/screens/migracao_magica_screen_actions.part.dart');
    expect(actions, contains('só da lista'));
  });
}
