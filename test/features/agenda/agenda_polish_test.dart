import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('agenda usa polish: rota, semantics, sheets tema', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/agenda_screen.dart',
    );
    final router = readRouterSourceBundle();

    expect(screen, contains("context.push('/agenda/novo'"));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, isNot(contains('NovoAgendamentoScreen')));
    expect(screen, isNot(contains('AlunoInsetFormField')));
    expect(screen, isNot(contains('agendaNovoTileLabel()')));
    expect(screen, isNot(contains('agendaHorarioConfirmLabel()')));
    expect(screen, isNot(contains('Selecione quem será atendido')));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('FxHomeSheetSurface'));
    expect(screen, contains('FxHomeSheetHeader'));
    expect(screen, contains('AgendaMonthGrid'));
    expect(screen, isNot(contains('AgendaMonthBar')));
    expect(screen, isNot(contains('AgendaTodayPill')));
    expect(screen, contains('onToday:'));
    expect(screen, contains('agendaVisibleByDay'));
    expect(screen, isNot(contains('AgendaWeekBar')));
    expect(screen, contains('showAgendaHelpSheet'));
    expect(screen, contains('agendaEventTitle'));
    expect(screen, contains('AgendaHubHeader'));
    expect(screen, isNot(contains('AgendaNextBanner')));
    expect(screen, contains('AgendaDaySheet'));
    expect(screen, contains('DashboardLayout.bottomDockClearance'));
    expect(
      screen,
      isNot(contains("safePopOrGo(context, '/dashboard/personal')")),
    );
    expect(screen, isNot(contains('arrow_back')));
    expect(screen, isNot(contains('LayoutBuilder(')));
    expect(screen, contains('listarMes'));
    expect(screen, contains('agendaEventSessionNote'));
    expect(screen, isNot(contains('maskEmailForList')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('FxLiquidSecondaryButton')));
    expect(screen, contains('_AgendaMetaStrip'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('explicitChildNodes: true'));
    expect(screen, isNot(contains('ListTile(')));
    expect(screen, isNot(contains('MaterialPageRoute')));
    expect(screen, isNot(contains('quem sera atendido')));
    expect(screen, contains('constrainWidth: false'));
    expect(
      File(
        'lib/features/agenda/widgets/agenda_day_sheet.dart',
      ).readAsStringSync(),
      allOf(
        contains('FxHomeSheetSurface'),
        contains('FxSatelliteListTile'),
      ),
    );
    expect(
      File(
        'lib/features/agenda/widgets/agenda_event_card.dart',
      ).readAsStringSync(),
      contains('FxSatelliteListTile'),
    );
    expect(
      File(
        'lib/features/agenda/widgets/agenda_day_sheet.dart',
      ).readAsStringSync(),
      allOf(contains('FxEmptyState'), isNot(contains('FxEmptyAction'))),
    );
    expect(screen, contains('_eventActions'));
    expect(screen, contains('_danger'));
    expect(screen, isNot(contains('Icons.delete_outline_rounded')));
    expect(screen, isNot(contains('? () {}')));
    expect(screen, isNot(contains('label: agendaHorarioConfirmLabel')));
    expect(screen, isNot(contains('agendaHorarioConfirmLabel()')));

    expect(router, contains("path: '/agenda/novo'"));
    expect(router, contains('NovoAgendamentoScreen('));
  });
}
