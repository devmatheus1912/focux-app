import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('novo agendamento é S5 com CTA líquido', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/novo_agendamento_screen.dart',
    );
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('label: agendaNovoTileLabel()'));
    expect(screen, isNot(contains('ElevatedButton')));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('Selecione quem será atendido'));
    expect(screen, contains('picker: true'));
    expect(screen, contains('AgendaAlunoSheet'));
    expect(screen, contains('AgendaDateTimeSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains("label: 'Aluno'"));
    expect(screen, contains("label: 'Início'"));
    expect(screen, contains('maskEmailForList'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('agendaNovoSalvarTooltip')));
  });

  test('sheets de horário e aluno confirmam no tipo certo', () {
    final sheets = readScreenSourceBundle(
      'lib/features/agenda/widgets/agenda_form_sheets.dart',
    );
    expect(sheets, contains('FxLiquidPrimaryButton'));
    expect(sheets, contains('agendaHorarioConfirmLabel()'));
    expect(sheets, isNot(contains('ElevatedButton')));
    expect(sheets, contains('class AgendaAlunoSheet'));
    expect(sheets, contains('class AgendaDateTimeSheet'));
    expect(sheets, contains('maskEmailForList'));
  });
}
