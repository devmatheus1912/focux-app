import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno equipamentos cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/alunos/screens/aluno_equipamentos_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    // Escolha no topo, atalhos e lista num grupo só, sem ícone por equipamento.
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('Qualquer equipamento'));
    expect(screen, contains('Só o que o aluno tem'));
    expect(screen, contains('equipamentosAtalhos'));
    expect(screen, isNot(contains('FxSatelliteListTile')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('equipamentosMarcadosLabel'));
    expect(screen, isNot(contains('equipamentoFxIcon')));
    expect(screen, isNot(contains('Sem restrição')));
    expect(screen, contains('Switch.adaptive'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('_dirty'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('onBack: _cancel'));
    expect(screen, isNot(contains("child: const Text('Cancelar')")));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('FilterChip')));
    expect(screen, isNot(contains('OutlinedButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('DashboardSectionHeader')));
  });
}
