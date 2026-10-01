import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/ia_progressao_carga_result.dart';

void main() {
  final api = {
    'resposta': 'resumo do servidor',
    'intro': 'Contexto curto.',
    'footer': 'Respeite a técnica.',
    'sugestoesRegistradas': 1,
    'exercicios': [
      {
        'exercicio': 'Supino',
        'cargaAtual': '80 kg · 3×8',
        'cargaSugerida': '82,5 kg · 3×8',
        'justificativa': 'Fez 80 kg×8 nas 3 últimas.',
        'deltaKg': 2.5,
        'treinoExercicioId': 11,
      },
    ],
  };

  test('fromApi lê os exercícios estruturados', () {
    final result = IaProgressaoCargaResult.fromApi(api);

    expect(result.exercises, hasLength(1));
    expect(result.exercises.first.deltaLabel, '+2,5 kg');
    expect(result.exercises.first.treinoExercicioId, 11);
    expect(result.sugestoesRegistradas, 1);
  });

  test('toPlainText leva aluno, data e itens', () {
    final text = IaProgressaoCargaResult.fromApi(api).toPlainText(
      alunoNome: 'Ana',
      geradoLabel: 'Gerado em 30/09/2026 10:00',
    );

    expect(text, startsWith('Progressão de carga · Ana'));
    expect(text, contains('Gerado em 30/09/2026 10:00'));
    expect(text, contains('• Supino'));
    expect(text, contains('80 kg · 3×8 → 82,5 kg · 3×8 (+2,5 kg)'));
    expect(text, endsWith('Respeite a técnica.'));
  });
}
