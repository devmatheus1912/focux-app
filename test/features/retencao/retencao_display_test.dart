import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/retencao/data/retencao_repository.dart';
import 'package:focux_app/features/retencao/utils/retencao_display.dart';
import 'package:focux_app/features/retencao/utils/retencao_fila.dart';

RetencaoAlunoScore _aluno(int id, {List<String> motivos = const []}) =>
    RetencaoAlunoScore(
      alunoId: id,
      alunoNome: 'Aluno $id',
      nivel: 'ALTO',
      motivos: motivos,
    );

RetencaoHome _home({int alto = 0, int? antes}) => RetencaoHome(
  alto: alto,
  medio: 0,
  saudavel: 0,
  top3: const [],
  altoSemanaAnterior: antes,
);

void main() {
  test('nível vem do servidor', () {
    expect(RetencaoNivel.de('ALTO'), RetencaoNivel.alto);
    expect(RetencaoNivel.de('MEDIO'), RetencaoNivel.atencao);
    expect(RetencaoNivel.de('BAIXO'), RetencaoNivel.saudavel);
    expect(RetencaoNivel.de('?'), RetencaoNivel.saudavel);
  });

  test('motivo principal e quantos mais', () {
    expect(retencaoMotivoCurto(_aluno(1)), isNull);
    expect(retencaoMotivoCurto(_aluno(1, motivos: ['A'])), 'A');
    expect(retencaoMotivoCurto(_aluno(1, motivos: ['A', 'B'])), 'A · +1');
  });

  test('comparação com a semana passada', () {
    expect(retencaoVariacaoSemanal(_home(alto: 3)), isNull);
    expect(retencaoVariacaoSemanal(_home(alto: 3, antes: 3)), isNull);
    expect(
      retencaoVariacaoSemanal(_home(alto: 3, antes: 1)),
      '2 a mais que na semana passada',
    );
    expect(
      retencaoVariacaoSemanal(_home(alto: 1, antes: 2)),
      '1 a menos que na semana passada',
    );
  });

  test('fila não repete quem está em Chamar agora', () {
    final a = _aluno(1);
    final b = _aluno(2);
    expect(filaSem([a, b], [a]), [b]);
  });
}
