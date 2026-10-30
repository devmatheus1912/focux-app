import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/treinos_hub_view.dart';

ExecucaoTreino _aberta(int treinoId, DateTime inicio, {int feitos = 0}) => ExecucaoTreino.fromJson({
  'id': 9,
  'treinoId': treinoId,
  'treinoNome': 'Treino B',
  'status': 'EM_ANDAMENTO',
  'iniciadoEm': inicio.toIso8601String(),
  'exerciciosConcluidos': feitos,
});

ExecucaoTreino _feito(int treinoId, DateTime em, String nome) => ExecucaoTreino.fromJson({
  'id': treinoId,
  'treinoId': treinoId,
  'treinoNome': nome,
  'status': 'CONCLUIDO',
  'iniciadoEm': em.subtract(const Duration(minutes: 40)).toIso8601String(),
  'concluidoEm': em.toIso8601String(),
  'exerciciosConcluidos': 3,
});

void main() {
  final agora = DateTime(2026, 10, 30, 10); // sexta

  test('aberta em outro dia é antiga', () {
    expect(sessaoAntigaAberta([_aberta(2, DateTime(2026, 10, 28, 9), feitos: 2)], agora), isNotNull);
  });

  test('de hoje com progresso não é antiga', () {
    expect(sessaoAntigaAberta([_aberta(2, DateTime(2026, 10, 30, 9), feitos: 1)], agora), isNull);
  });

  test('de hoje, vazia e de outro treino é antiga; do treino de hoje, não', () {
    final aberta = _aberta(2, DateTime(2026, 10, 30, 9));
    expect(sessaoAntigaAberta([aberta], agora, treinoDeHojeId: 3), isNotNull);
    expect(sessaoAntigaAberta([aberta], agora, treinoDeHojeId: 2), isNull);
  });

  test('feitos da semana guarda nome e treino do dia em que aconteceu', () {
    final feitos = feitosDaSemana([_feito(1, DateTime(2026, 10, 29, 9), 'A · Peito')], agora);
    expect(feitos[4]?.nome, 'A · Peito');
    expect(feitos[4]?.treinoId, 1);
    expect(diasFeitosNaSemana([_feito(1, DateTime(2026, 10, 29, 9), 'A')], agora), {4});
  });
}
