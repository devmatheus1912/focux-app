import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno equipamentos cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/alunos/screens/aluno_equipamentos_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains("icon: 'circle-check'"));
    expect(screen, isNot(contains('FilterChip')));
    expect(screen, isNot(contains('OutlinedButton')));
    expect(screen, isNot(contains('Icons.check_rounded')));
    expect(screen, isNot(contains('FloatingActionButton')));
  });
}
