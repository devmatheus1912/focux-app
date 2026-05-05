import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';

void main() {
  test('parse Exercicio com taxonomia estruturada', () {
    final ex = Exercicio.fromJson({
      'id': 1,
      'nome': 'Supino reto barra',
      'modalidade': 'MUSCULACAO',
      'padraoMovimento': 'PUSH_HORIZONTAL',
      'grupoMuscularPrimario': 'PEITO',
      'gruposSecundarios': 'TRICEPS,OMBRO_ANTERIOR',
      'equipamentosCurado': 'BARRA,BANCO',
      'espacosCompativeis': 'ACADEMIA_COMPLETA,ACADEMIA_BASICA',
      'dificuldade': 'INTERMEDIARIO',
      'unilateral': false,
      'curado': true,
      'curatedId': 1,
      'editorialStatus': 'APPROVED',
      'videoSource': 'PRODUCTION_PENDING',
    });

    expect(ex.modalidade, Modalidade.musculacao);
    expect(ex.padraoMovimento, PadraoMovimento.pushHorizontal);
    expect(ex.grupoMuscularPrimario, GrupoMuscular.peito);
    expect(ex.gruposSecundarios, contains(GrupoMuscular.triceps));
    expect(ex.equipamentos, contains(Equipamento.barra));
    expect(ex.espacosCompativeis, contains(Espaco.academiaCompleta));
    expect(ex.dificuldade, Dificuldade.intermediario);
    expect(ex.curado, isTrue);
    expect(ex.curatedId, 1);
  });

  test('production pending sem video tocavel', () {
    final ex = Exercicio.fromJson({
      'id': 2,
      'nome': 'Flexao',
      'videoSource': 'PRODUCTION_PENDING',
    });

    expect(ex.hasPlayableMedia, isFalse);
    expect(ex.isProductionPending, isTrue);
  });
}
