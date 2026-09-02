import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('add aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/alunos/screens/add_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('showAddAlunoSenhaSheet'));
    final senha = readScreenSourceBundle(
      'lib/features/alunos/widgets/add_aluno_senha_sheet.dart',
    );
    expect(senha, contains('copySensitiveToClipboard'));
    expect(senha, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, contains('Outro objetivo'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains("icon: 'circle-check'"));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('bottomNavigationBar')));
    expect(screen, isNot(contains('DashboardHomeActionChip')));
    expect(screen, contains('enabled: _canSubmit && !_loading'));
    expect(screen, contains('FxErrorState'));
    expect(screen, isNot(contains('_ErrorCard')));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('BrPhone'));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('ProductEvents.alunoCreated'));
    expect(screen, contains('invalidateAlunosCaches'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showAddAlunoHelpSheet'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('AlunoChoiceSection'));
    expect(screen, contains('WhatsApp opcional'));
    expect(screen, isNot(contains('Complete nome e e-mail para cadastrar')));
    expect(screen, isNot(contains('abrimos o WhatsApp com a mensagem pronta')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(20));
  });
}
