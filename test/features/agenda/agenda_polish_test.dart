
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('agenda usa polish: rota, semantics, sheets tema', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/agenda_screen.dart',
    );
    final router = readRouterSourceBundle();

    expect(screen, contains('NovoAgendamentoScreen'));
    expect(screen, contains("context.push('/agenda/novo')"));
    expect(screen, contains('Selecione quem será atendido'));
    expect(screen, contains('_AgendaHorarioCard'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('loadingLabel: \'Agendando…\''));
    expect(screen, contains('FxInputDeco.outlineBorder'));
    expect(screen, contains('_agendaSheetDecoration'));
    expect(screen, contains('chrome.sheetFill'));
    expect(screen, contains('useSafeArea: true'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('explicitChildNodes: true'));
    expect(screen, isNot(contains('ListTile(')));
    expect(screen, isNot(contains('MaterialPageRoute')));
    expect(screen, isNot(contains('quem sera atendido')));

    expect(router, contains("path: '/agenda/novo'"));
    expect(router, contains('const NovoAgendamentoScreen()'));
  });
}
