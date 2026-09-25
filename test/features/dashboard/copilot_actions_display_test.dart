import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/copilot_actions_display.dart';

void main() {
  test('seletor de status mostra contagem quando disponível', () {
    const contagem = IaCommandActionsContagem(abertas: 4, adiadas: 1);
    expect(copilotActionsStatusChoiceLabel(copilotActionsStatusAberto, null), 'Abertas');
    expect(copilotActionsStatusChoiceLabel(copilotActionsStatusAberto, contagem), 'Abertas 4');
    expect(copilotActionsStatusChoiceLabel(copilotActionsStatusAdiado, contagem), 'Adiadas 1');
    expect(copilotActionsStatusChoiceLabel(copilotActionsStatusConcluido, contagem), 'Concluídas 0');
    expect(
      IaCommandActionsContagem.fromJson({'abertas': 2, 'concluidas': 7}).concluidas,
      7,
    );
  });

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
