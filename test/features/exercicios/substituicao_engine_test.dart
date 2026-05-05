import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/data/substituicao_engine.dart';

Exercicio _ex({
  required int id,
  required String nome,
  required Modalidade modalidade,
  required PadraoMovimento padrao,
  required GrupoMuscular grupo,
  List<Equipamento> equip = const [Equipamento.barra],
  Dificuldade dif = Dificuldade.intermediario,
  bool unilateral = false,
}) {
  return Exercicio(
    id: id,
    nome: nome,
    modalidade: modalidade,
    padraoMovimento: padrao,
    grupoMuscularPrimario: grupo,
    equipamentos: equip,
    dificuldade: dif,
    unilateral: unilateral,
    gruposSecundarios: const [],
    espacosCompativeis: const [],
  );
}

void main() {
  final supinoBarra = _ex(
    id: 1,
    nome: 'Supino barra',
    modalidade: Modalidade.musculacao,
    padrao: PadraoMovimento.pushHorizontal,
    grupo: GrupoMuscular.peito,
    equip: [Equipamento.barra, Equipamento.banco],
  );
  final supinoHalter = _ex(
    id: 2,
    nome: 'Supino halter',
    modalidade: Modalidade.musculacao,
    padrao: PadraoMovimento.pushHorizontal,
    grupo: GrupoMuscular.peito,
    equip: [Equipamento.halter, Equipamento.banco],
  );
  final remadaBarra = _ex(
    id: 3,
    nome: 'Remada barra',
    modalidade: Modalidade.musculacao,
    padrao: PadraoMovimento.pullHorizontal,
    grupo: GrupoMuscular.costasLatissimo,
    equip: [Equipamento.barra],
  );
  final flexao = _ex(
    id: 4,
    nome: 'Flexao',
    modalidade: Modalidade.musculacao,
    padrao: PadraoMovimento.pushHorizontal,
    grupo: GrupoMuscular.peito,
    equip: [Equipamento.pesoCorporal],
    dif: Dificuldade.iniciante,
  );

  test('top score usa mesmo padrao e grupo', () {
    final result = SubstituicaoEngine().encontrarAlternativas(
      alvo: supinoBarra,
      candidatos: [supinoBarra, supinoHalter, remadaBarra, flexao],
    );

    expect(result, isNotEmpty);
    expect(result.first.exercicio.id, supinoHalter.id);
    expect(result.any((r) => r.exercicio.id == remadaBarra.id), isFalse);
  });

  test('hard filter respeita equipamento do aluno', () {
    final result = SubstituicaoEngine().encontrarAlternativas(
      alvo: supinoBarra,
      candidatos: [supinoBarra, supinoHalter, flexao],
      equipamentosAluno: {Equipamento.halter, Equipamento.banco},
    );
    final ids = result.map((r) => r.exercicio.id).toList();

    expect(ids, contains(supinoHalter.id));
    expect(ids, isNot(contains(supinoBarra.id)));
    expect(ids, isNot(contains(flexao.id)));
  });

  test('sem perfil de equipamento nao filtra hard', () {
    final result = SubstituicaoEngine().encontrarAlternativas(
      alvo: supinoBarra,
      candidatos: [supinoBarra, supinoHalter, flexao],
    );

    expect(result.length, 2);
  });

  test('modalidade diferente nao entra', () {
    final caminhada = _ex(
      id: 5,
      nome: 'Caminhada',
      modalidade: Modalidade.cardio,
      padrao: PadraoMovimento.cardioEsteira,
      grupo: GrupoMuscular.fullBody,
    );
    final result = SubstituicaoEngine().encontrarAlternativas(
      alvo: supinoBarra,
      candidatos: [supinoHalter, caminhada],
    );
    final ids = result.map((r) => r.exercicio.id).toList();

    expect(ids, isNot(contains(caminhada.id)));
  });

  test('retorna maximo 5 alternativas', () {
    final extras = List.generate(
      10,
      (i) => _ex(
        id: 100 + i,
        nome: 'Variacao $i',
        modalidade: Modalidade.musculacao,
        padrao: PadraoMovimento.pushHorizontal,
        grupo: GrupoMuscular.peito,
      ),
    );
    final result = SubstituicaoEngine().encontrarAlternativas(
      alvo: supinoBarra,
      candidatos: extras,
    );

    expect(result.length, 5);
  });
}
