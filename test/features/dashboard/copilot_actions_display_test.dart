import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/copilot_actions_display.dart';

FilaAcaoResumo _a(
  String titulo, {
  String descricao = '',
  int? alunoId = 7,
  String? resolvedAt,
}) => FilaAcaoResumo.fromJson({
  'tipo': 'IA_COPILOTO',
  'actionKey': titulo,
  'titulo': titulo,
  'descricao': descricao,
  'alunoId': alunoId,
  'resolvedAt': resolvedAt,
});

void main() {
  test('contagem por status', () {
    expect(
      IaCommandActionsContagem.fromJson({
        'abertas': 2,
        'concluidas': 7,
      }).concluidas,
      7,
    );
    expect(copilotActionsStatusLabel(copilotActionsStatusAberto), 'Abertas');
    expect(copilotActionsStatusLabel(copilotActionsStatusAdiado), 'Adiadas');
    expect(copilotActionsStatusLabel(copilotActionsStatusConcluido), 'Feitas');
    expect(
      copilotActionsEmptyTitle(copilotActionsStatusAberto),
      'Nada pendente',
    );
    expect(copilotActionsComoCalculamos, contains('alertas'));
  });

  test('título é o aluno; o motivo diz o que fazer', () {
    final a = _a('Revisar ação do copiloto de Julio Cesar');
    expect(
      copilotActionsMotivoParaPersonal(a, nomeAluno: 'Julio Cesar'),
      'Revisar a ação da IA Focux',
    );
  });

  test('feita diz quando e repetidas viram uma', () {
    final agora = DateTime(2026, 11, 12, 20);
    expect(
      copilotActionsFeitaHa(
        _a('x', resolvedAt: '2026-11-10T09:00:00'),
        agora: agora,
      ),
      'Feita há 2 dias',
    );
    expect(
      copilotActionsFeitaHa(
        _a('x', resolvedAt: '2026-11-12T09:00:00'),
        agora: agora,
      ),
      'Feita hoje',
    );
    final r = copilotActionsSemRepetir([
      _a('Julio Cesar', descricao: 'Julio · mapa corporal'),
      _a('Julio Cesar ', descricao: 'Julio · mapa corporal'),
    ]);
    expect(r, hasLength(1));
    expect(copilotActionsMotivo(r.single), 'Falta medir o mapa corporal');
  });
}
