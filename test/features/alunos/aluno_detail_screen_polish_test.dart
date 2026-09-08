import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno detail cumpre contrato Tier S+', () {
    final screen = [
      readScreenSourceBundle(
        'lib/features/alunos/screens/aluno_detail_screen.dart',
      ),
      File(
        'lib/features/alunos/widgets/aluno360_operacao_sticky_cta.dart',
      ).readAsStringSync(),
      File(
        'lib/features/alunos/constants/aluno_360_layout.dart',
      ).readAsStringSync(),
    ].join('\n');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('onLista'));
    expect(screen, contains('subtitle: freshness'));
    expect(screen, contains("title: 'Não conseguimos carregar o aluno'"));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
