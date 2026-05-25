import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agenda usa polish 10/10: rota, semantics, sheets tema', () {
    final screen =
        File('lib/features/agenda/screens/agenda_screen.dart').readAsStringSync();
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(screen, contains('NovoAgendamentoScreen'));
    expect(screen, contains("context.push('/agenda/novo')"));
    expect(screen, contains('Selecione quem será atendido'));
    expect(screen, contains('_AgendaDateTimeField'));
    expect(screen, contains('_agendaSheetDecoration'));
    expect(screen, contains('chrome.sheetFill'));
    expect(screen, contains('useSafeArea: true'));
    expect(screen, contains('Semantics('));
    expect(screen, isNot(contains('ListTile(')));
    expect(screen, isNot(contains('MaterialPageRoute')));
    expect(screen, isNot(contains('quem sera atendido')));

    expect(router, contains("path: '/agenda/novo'"));
    expect(router, contains('const NovoAgendamentoScreen()'));
  });
}
