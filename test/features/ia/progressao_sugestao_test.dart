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
