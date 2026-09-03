import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('agenda usa polish: rota, semantics, sheets tema', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/agenda_screen.dart',
    );
    final router = readRouterSourceBundle();

    expect(screen, contains('NovoAgendamentoScreen'));
    expect(screen, contains("context.push('/agenda/novo'"));
    expect(screen, contains('Selecione quem será atendido'));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('agendaNovoTileLabel()'));
    expect(screen, isNot(contains('label: agendaNovoTileLabel')));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('FxHomeSheetSurface'));
    expect(screen, contains('FxHomeSheetHeader'));
    expect(screen, contains('AgendaDayChip'));
    expect(screen, contains('showAgendaHelpSheet'));
    expect(screen, contains('agendaEventTitle'));
    expect(screen, contains('AgendaHubHeader'));
    expect(screen, contains('AgendaNextBanner'));
    expect(screen, contains('agendaBuildDayLane'));
    expect(screen, contains('agendaDayHeading'));
    expect(screen, contains('DashboardLayout.bottomDockClearance'));
    expect(
      screen,
      isNot(contains("safePopOrGo(context, '/dashboard/personal')")),
    );
    expect(screen, isNot(contains('arrow_back')));
    expect(screen, isNot(contains('LayoutBuilder(')));
    expect(screen, contains('listarSemana'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('maskEmailForList'));
    expect(screen, contains('agendaEventSessionNote'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('FxLiquidSecondaryButton')));
    expect(screen, contains('_AgendaMetaStrip'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('explicitChildNodes: true'));
    expect(screen, isNot(contains('ListTile(')));
    expect(screen, isNot(contains('MaterialPageRoute')));
    expect(screen, isNot(contains('quem sera atendido')));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains('_eventActions'));
    expect(screen, contains('_danger'));
    expect(screen, isNot(contains('Icons.delete_outline_rounded')));
    expect(screen, isNot(contains('? () {}')));
    expect(screen, isNot(contains('label: agendaHorarioConfirmLabel')));
    expect(screen, contains('agendaHorarioConfirmLabel()'));

    expect(router, contains("path: '/agenda/novo'"));
    expect(router, contains('NovoAgendamentoScreen('));
  });
}
