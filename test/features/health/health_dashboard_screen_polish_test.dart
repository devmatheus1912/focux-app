import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('health dashboard cumpre contrato S1 hub Saúde', () {
    final screen = readScreenSourceBundle(
      'lib/features/health/screens/health_dashboard_screen.dart',
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
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('showBack: false'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('RecoveryScoreRing'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('Prontidão'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('saudeAtualizarLabel'));
    expect(screen, contains('saudeSyncSoftError'));
    expect(screen, contains('_syncSoftError'));
    expect(screen, contains('_SaudeSoftSyncBanner'));
    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('AlwaysScrollableScrollPhysics'));
    expect(screen, contains('homeHelpOpened'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxActionChip'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains('refresh-cw'));
    expect(screen, contains('_refreshing'));
    expect(screen, contains('Expanded('));
    expect(screen, contains('Atualizar'));
    expect(screen, isNot(contains('class _MetricCard')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('prontidão da Home vem do BFF, sem sync próprio nem texto fixo', () {
    final card = readScreenSourceBundle(
      'lib/features/health/widgets/aluno_recovery_card.dart',
    );
    expect(card, contains('extends StatelessWidget'));
    expect(card, contains('s.alunoProntidaoSincronizar'));
    expect(card, contains('fxListCardDecoration'));
    expect(card, isNot(contains('Provider')));
    expect(card, isNot(contains('syncTodayIfPermitted')));
    expect(card, isNot(contains('TextStyle(')));
  });
}
