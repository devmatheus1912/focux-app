import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/copiloto_analise.dart';
import 'package:focux_app/features/ia/screens/ia_copiloto_screen.dart';

Map<String, dynamic> _rec(int id, {String estado = 'PENDENTE', String? tipoAcao}) => {
  'id': id,
  'tipo': 'RISCO',
  'titulo': 'Recomendação $id',
  'descricao': 'O que vimos',
  'recomendacao': 'O que fazer',
  'status': 'READY',
  'tipoAcao': tipoAcao,
  'estado': estado,
};

void main() {
  final analise = CopilotoAnalise.fromJson({
    'id': 9,
    'alunoId': 2,
    'alunoNome': 'Julio Cesar',
    'criadaEm': '2026-11-11T10:00:00',
    'recomendacoes': [
      _rec(1, estado: 'FEITA'),
      _rec(2),
      _rec(3, estado: 'DISPENSADA'),
    ],
  });

  test('lê do servidor com o estado de cada recomendação', () {
    expect(analise.recomendacoes.map((r) => r.estado), [
      CopilotoEstado.feita,
      CopilotoEstado.pendente,
      CopilotoEstado.dispensada,
    ]);
    expect(analise.proximaPendente!.id, 2);
  });

  test('marcar feita, dispensar e desfazer', () {
    final r2 = analise.recomendacoes[1];
    final feita = analise.comRecomendacao(
      r2.copyWith(estado: CopilotoEstado.feita, resultado: 'MENSAGEM_ENVIADA'),
    );
    expect(feita.proximaPendente, isNull);
    expect(feita.recomendacoes[1].resultado, 'MENSAGEM_ENVIADA');
    final desfeita = feita.comRecomendacao(
      feita.recomendacoes[1].copyWith(estado: CopilotoEstado.pendente),
    );
    expect(desfeita.proximaPendente!.id, 2);
    expect(desfeita.recomendacoes[1].resultado, isNull);
  });

  test('linha de "Análises recentes"', () {
    final agora = DateTime(2026, 11, 11, 18);
    CopilotoAnaliseResumo r({DateTime? criada, int feitas = 0, int disp = 0, DateTime? concluida}) =>
        CopilotoAnaliseResumo(
          id: 1,
          alunoId: 2,
          total: 3,
          feitas: feitas,
          dispensadas: disp,
          criadaEm: criada,
          concluidaEm: concluida,
        );
    expect(copilotoResumoLinha(r(criada: DateTime(2026, 11, 11, 9), feitas: 2), agora), 'Hoje · 2 de 3 feitas');
    expect(copilotoResumoLinha(r(criada: DateTime(2026, 11, 10, 9), concluida: DateTime(2026, 11, 10)), agora), 'Ontem · Concluída');
    expect(copilotoResumoLinha(r(criada: DateTime(2026, 11, 3, 9)), agora), '03/11 · 3 pendentes');
  });

  test('rótulo do que foi feito', () {
    expect(copilotoResultadoLabel('MENSAGEM_ENVIADA'), 'Mensagem enviada');
    expect(copilotoResultadoLabel('TAREFA_CRIADA'), 'Tarefa criada');
  });
}
