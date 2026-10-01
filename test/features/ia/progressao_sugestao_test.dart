import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/progressao_sugestao.dart';

void main() {
  test('fromApi maps structured suggestion', () {
    final item = ProgressaoSugestao.fromApi({
      'id': 7,
      'alunoId': 12,
      'alunoNome': 'Beatriz Carvalho',
      'exercicio': 'Supino',
      'cargaAtual': '80kg 4x20',
      'cargaSugerida': '82,5kg 4x18-20',
      'justificativa': 'Progressão segura.',
      'deltaKg': 2.5,
      'exercicioBibliotecaId': 44,
    });

    expect(item.exercicio, 'Supino');
    expect(item.deltaLabel, '+2,5 kg');
    expect(item.exercicioBibliotecaId, 44);
    expect(item.status, ProgressaoSugestao.statusPendente);
    expect(item.naoEncontrada, isFalse);
  });

  test('fromApi lê séries, reps e status', () {
    final item = ProgressaoSugestao.fromApi({
      'id': 8,
      'alunoId': 12,
      'exercicio': 'Remada',
      'cargaAnteriorKg': 40,
      'cargaSugeridaKg': 42.5,
      'seriesSugeridas': 4,
      'repeticoesSugeridas': '8-10',
      'status': 'NAO_ENCONTRADA',
    });

    expect(item.cargaAtual, '40 kg');
    expect(item.cargaSugerida, '42,5 kg');
    expect(item.seriesSugeridas, 4);
    expect(item.repeticoesSugeridas, '8-10');
    expect(item.naoEncontrada, isTrue);
  });

  test('contexto e aceitar-todas fromApi', () {
    final ctx = ProgressaoContextoResumo.fromApi({
      'treinos': ['Treino A', 'Treino B'],
      'exercicios': 8,
      'exerciciosComHistorico': 6,
      'sessoes4Semanas': 5,
    });
    expect(ctx.treinos, ['Treino A', 'Treino B']);
    expect(ctx.sessoes4Semanas, 5);

    final r = ProgressaoAceitarTodasResponse.fromApi({
      'aplicadas': 3,
      'naoEncontradas': 1,
    });
    expect(r.aplicadas, 3);
    expect(r.naoEncontradas, 1);
  });

  test('ProgressaoAceitarResponse fromApi', () {
    final response = ProgressaoAceitarResponse.fromApi({
      'cargaAplicada': false,
      'mensagem': 'Ajuste manualmente.',
    });

    expect(response.cargaAplicada, isFalse);
    expect(response.mensagem, 'Ajuste manualmente.');
  });
}
