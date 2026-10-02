import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('novo agendamento é S5 com CTA líquido', () {
    final screen = readScreenSourceBundle(
      'lib/features/agenda/screens/novo_agendamento_screen.dart',
    );
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('agendaNovoDiscardTitle'));
    expect(screen, contains("child: const Text('Cancelar')"));
    expect(screen, contains('label: agendaNovoTileLabel()'));
    expect(screen, isNot(contains('ElevatedButton')));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('Selecione quem será atendido'));
    expect(screen, contains('picker: true'));
    expect(screen, contains('AgendaAlunoSheet'));
    expect(screen, contains('showAgendaSlotPicker'));
    expect(screen, contains('agendaSlotLocalError'));
    expect(screen, contains('agendaSlotErrorMessage'));
    expect(screen, isNot(contains("label: 'Fim'")));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains("label: 'Aluno'"));
    expect(screen, contains("label: 'Quando'"));
    expect(screen, contains('maskEmailForList'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('agendaNovoSalvarTooltip')));
  });

  test('sheets de horário e aluno confirmam no tipo certo', () {
    final sheets = readScreenSourceBundle(
      'lib/features/agenda/widgets/agenda_form_sheets.dart',
    );
    final picker = readScreenSourceBundle(
      'lib/features/agenda/widgets/agenda_slot_picker_sheet.dart',
    );
    expect(picker, contains('FxLiquidPrimaryButton'));
    expect(picker, contains('agendaHorarioConfirmLabel()'));
    expect(picker, isNot(contains('ElevatedButton')));
    expect(picker, contains('class AgendaSlotPickerSheet'));
    expect(sheets, contains('class AgendaAlunoSheet'));
    expect(sheets, isNot(contains('AgendaDateTimeSheet')));
    expect(sheets, contains('maskEmailForList'));
  });
}
