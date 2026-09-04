import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/copilot_actions_display.dart';

void main() {
  test('copy do filtro e confirmações das tarefas IA', () {
    expect(copilotActionsStatusLabel(copilotActionsStatusAberto), 'Abertas');
    expect(copilotActionsStatusLabel(copilotActionsStatusAdiado), 'Adiadas');
    expect(copilotActionsStatusLabel(copilotActionsStatusConcluido), 'Concluídas');
    expect(copilotActionsEmptyTitle(copilotActionsStatusAberto), contains('aberta'));
    expect(copilotActionsCompleteConfirmTitle(), contains('Concluir'));
    expect(copilotActionsSnoozeConfirmMessage(), contains('adiadas'));
    expect(copilotActionsOpenAlunoLabel(false), 'Revisar aluno');
    expect(copilotActionsOpenAlunoLabel(true), 'Ver aluno');
    expect(copilotActionsSectionDetail(copilotActionsStatusAberto, 2), '2 abertas');
    expect(copilotActionsComoCalculamos, contains('Radar'));
    expect(copilotActionsComoCalculamos, contains('pagina'));
  });
}
