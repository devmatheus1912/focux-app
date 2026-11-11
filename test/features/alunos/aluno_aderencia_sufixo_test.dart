import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/alunos_list_utils.dart';

void main() {
  test('o ponto colorido ganha sentido fora do verde', () {
    expect(alunoListAderenciaSufixo(80, rotulo: '5 de 7 dias com treino'), '');
    expect(alunoListAderenciaSufixo(60, rotulo: '2 de 7 dias com treino'), ' · abaixo do previsto');
    expect(alunoListAderenciaSufixo(20, rotulo: '1 de 7 dias com treino'), ' · parado');
    expect(alunoListAderenciaSufixo(20, rotulo: 'Parado há 9d'), '');
    expect(alunoListAderenciaSufixo(null, rotulo: 'x'), '');
  });
}
