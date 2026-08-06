import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('esqueci senha cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/auth/screens/esqueci_senha_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));

    // Segue o mesmo padrão de estado/rede das outras telas de auth.
    expect(screen, contains('ConsumerStatefulWidget'));
    expect(screen, contains('authRepositoryProvider'));

    // Toggle de papel reutilizado (com haptics) e lockup de 118px.
    expect(screen, contains('AuthRoleToggle'));
    expect(screen, contains('width: 118'));

    // Papel é lido da query e propagado de volta ao login.
    expect(screen, contains("params['role']"));
    expect(screen, contains("params['p']"));
    expect(screen, contains('personalSlug:'));
    expect(screen, contains(r"role=${_isAluno ? 'aluno' : 'personal'}"));
  });
}
