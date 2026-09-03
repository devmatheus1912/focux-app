import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_copiloto_display.dart';

void main() {
  test('copy do copiloto confirma gasto de cota e persistência', () {
    expect(iaCopilotoGerarLabel('Treino'), 'Gerar Treino');
    expect(iaCopilotoGerarConfirmTitle('Treino'), 'Gerar Treino com IA?');
    expect(iaCopilotoGerarConfirmMessage(), contains('cota de IA'));
    expect(iaCopilotoCriarTarefaLabel(), 'Criar tarefa');
    expect(iaCopilotoCriarTarefaConfirmTitle(), contains('Salvar tarefa'));
    expect(iaCopilotoAbrirAlunoLabel(), 'Abrir aluno');
    expect(iaCopilotoVerTarefaLabel(), 'Ver tarefa');
    expect(iaCopilotoComoCalculamos, contains('você pede'));
  });
}
