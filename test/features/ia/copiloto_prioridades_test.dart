import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/copilot_actions_display.dart';
import 'package:focux_app/features/ia/copilot_insight_text.dart';
import 'package:focux_app/features/ia/models/ia_copilot_insight.dart';
import 'package:focux_app/features/ia/utils/ia_copiloto_display.dart';

FilaAcaoResumo _acao(int aluno, {String prioridade = 'P1', String descricao = 'Hugo · mapa corporal'}) =>
    FilaAcaoResumo.fromJson({
      'tipo': 'FOCUX_SCORE',
      'actionKey': 'FOCUX_SCORE_$aluno',
      'titulo': 'Radar Focux: Hugo',
      'descricao': descricao,
      'acaoUrl': '/alunos/$aluno',
      'prioridade': prioridade,
      'alunoId': aluno,
    });

void main() {
  test('recomendação da IA chega ao card', () {
    final i = IaCopilotInsight.fromJson({
      'tipo': 'RISCO',
      'titulo': 'Aderência em queda',
      'descricao': 'Faltou 3 vezes',
      'recomendacao': 'Ligar hoje',
    });
    expect(i.titulo, 'Aderência em queda');
    expect(i.recomendacao, 'Ligar hoje');
  });

  test('sem título usa o tipo, não um número', () {
    expect(copilotInsightTitulo({'tipo': 'RISCO'}, 0), 'Ponto de atenção');
    expect(copilotInsightTitulo({}, 1), 'Recomendação 2');
  });

  test('tarefa em linguagem do personal', () {
    final a = _acao(1);
    expect(copilotActionsNome(a), 'Hugo');
    expect(copilotActionsMotivo(a), 'Mapa corporal pendente');
    expect(copilotActionsSelo(_acao(1, prioridade: 'P0')), 'Hoje');
    expect(copilotActionsSelo(a), 'Esta semana');
    expect(copilotActionsDestino(a), '/alunos/1/evolucao');
  });

  test('prioridades: uma por aluno, urgentes antes, com limite', () {
    final lista = copilotoPrioridades(
      [_acao(1), _acao(1), _acao(2, prioridade: 'P0'), _acao(3)],
      {1: 'Hugo', 2: 'Julio', 3: 'Ana'},
      limite: 2,
    );
    expect(lista.map((p) => p.nome), ['Julio', 'Hugo']);
  });
}
