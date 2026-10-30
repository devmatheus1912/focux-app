import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_ficha_card.dart';

void main() {
  test('letra da sessão', () {
    expect(letraDaSessao('A · Peito e tríceps'), 'A');
    expect(letraDaSessao('Treino b'), 'B');
    expect(letraDaSessao('Peito e tríceps'), isNull);
  });
}
