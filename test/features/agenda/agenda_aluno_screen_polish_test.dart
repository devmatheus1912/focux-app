import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('agenda aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/agenda_aluno_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/aluno')"));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('meusAgendamentosPagina'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('canPop: false'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('icalTokenAluno'));
    expect(screen, contains('Confirmar presença'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('Nenhuma sessão marcada'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('markAlunoAgendaReviewed'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('context.pop()')));
    expect(screen, isNot(contains('FilledButton')));
  });
}
