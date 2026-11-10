import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/copilot_actions_display.dart';

FilaAcaoResumo _tarefa({
  String prioridade = 'P1',
  String titulo = 'Revisar treino de Julio Cesar',
  String descricao = 'Peça check-in ao aluno\n\nMotivo: 1 dia parado',
}) => FilaAcaoResumo(
  tipo: 'COPILOT',
  actionKey: 'k',
  titulo: titulo,
  descricao: descricao,
  acaoUrl: '/alunos/1',
  prioridade: prioridade,
  severidade: 'MEDIA',
  responsavel: 'Personal',
  sla: '24h',
  status: 'ABERTO',
  ctaLabel: 'Revisar aluno',
  iaSugerida: true,
  alunoId: 1,
);

void main() {
  test('uma tabela só: P1 é "Esta semana" no grupo e na pílula', () {
    final p1 = copilotActionsPrazo('P1');
    expect(p1.grupo, 'Esta semana');
    expect(p1.selo, 'Esta semana');
    expect(p1.aviso, isFalse);
    final grupos = copilotActionsPorGrupo([_tarefa()]);
    expect(grupos.single.$1, 'Esta semana');
    expect(copilotActionsSelo(_tarefa()), 'Esta semana');
    expect(copilotActionsPrazo('P0').aviso, isTrue);
    expect(copilotActionsPrazo('P0').selo, 'Hoje');
  });

  test('título da tarefa do Copiloto vira só o nome', () {
    expect(copilotActionsNome(_tarefa()), 'Julio Cesar');
  });

  test('o porquê vem do motivo salvo, não da instrução', () {
    expect(copilotActionsPorque(_tarefa()), '1 dia parado');
    expect(
      copilotActionsPorque(_tarefa(descricao: 'Ana · mapa corporal')),
      'Mapa corporal pendente',
    );
  });
}
