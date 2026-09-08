import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('plano sucesso cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/plano_sucesso/plano_sucesso_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showPlanoSucessoHelpSheet'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, isNot(contains('showDatePicker')));
    expect(screen, contains('revisarPlano'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains("icon: 'calendar'"));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('planoSucessoHubSubtitle'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains("'/alunos/\${widget.alunoId}/chat'"));
    expect(screen, isNot(contains('LinearGradient')));
    expect(screen, isNot(contains('Colors.white70')));
    expect(screen, isNot(contains('_SuccessRing')));
    expect(screen, isNot(contains('Aluno #')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
