import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/features/checkin/utils/execucao_metodos.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/metodo_exercicio.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/utils/combinados.dart';
import 'package:focux_app/features/treinos/widgets/aplicar_em_alunos_folha.dart';

TreinoExercicioItem _item(int id, {int? grupo, String? rotulo, String bloco = 'TRABALHO'}) => TreinoExercicioItem(
  id: id,
  exercicio: Exercicio(id: id + 100, nome: 'Ex $id'),
  series: 4,
  repeticoes: '10',
  ordem: id,
  bloco: bloco,
  metodo: MetodoExercicio(grupo: grupo, grupoRotulo: rotulo),
);

ExecucaoExercicio _exec(int id, {int? grupo, int feitas = 0, int series = 3}) => ExecucaoExercicio(
  id: id,
  treinoExercicioId: id,
  exercicioNome: 'Ex $id',
  series: series,
  seriesFeitas: feitas,
  concluido: feitas >= series,
  metodo: MetodoExercicio(grupo: grupo),
);

void main() {
  group('MetodoExercicio.fromJson', () {
    test('lê o método novo', () {
      final m = MetodoExercicio.fromJson({
        'tecnica': 'DROPSET',
        'quedas': 3,
        'reducaoPct': 20,
        'grupo': 2,
        'grupoRotulo': 'BISET',
      });
      expect(m.tecnica, Tecnica.dropset);
      expect(m.quedas, 3);
      expect(m.combinado, isTrue);
    });

    test('resposta antiga: SUPERSET vira combinado com técnica normal', () {
      final m = MetodoExercicio.fromJson(null, tipoSerie: 'SUPERSET', grupoSuperset: 1);
      expect(m.tecnica, Tecnica.normal);
      expect(m.grupo, 1);
      expect(m.grupoRotulo, 'SUPERSET');
    });
  });

  test('pirâmide crescente e decrescente', () {
    final sobe = linhasDaPiramide(series: 4, crescente: true, repsBase: '8-12', carga: 20);
    expect(sobe.map((l) => l.reps), ['12', '10', '8', '6']);
    expect(sobe.map((l) => l.carga), [20, 22, 24, 26]);
    final desce = linhasDaPiramide(series: 4, crescente: false, repsBase: '8-12');
    expect(desce.map((l) => l.reps), ['6', '8', '10', '12']);
    expect(desce.first.carga, isNull);
  });

  group('combinados', () {
    test('combinar com o próximo cria bi-set, e de novo vira tri-set', () {
      final itens = [_item(1), _item(2), _item(3)];
      final bi = combinarComProximo(itens, 1)!;
      expect(bi.single.itens, [1, 2]);

      final comBi = [_item(1, grupo: 1), _item(2, grupo: 1), _item(3)];
      expect(combinarComProximo(comBi, 2)!.single.itens, [1, 2, 3]);
    });

    test('não combina com outro bloco nem sem próximo', () {
      final itens = [_item(1), _item(2, bloco: 'ALONGAMENTO')];
      expect(combinarComProximo(itens, 1), isNull);
      expect(combinarComProximo(itens, 2), isNull);
    });

    test('separar tira o grupo inteiro; superset alterna o nome', () {
      final itens = [_item(1, grupo: 1), _item(2, grupo: 1), _item(3, grupo: 2), _item(4, grupo: 2)];
      expect(separar(itens, 2).single.itens, [3, 4]);
      expect(alternarSuperset(itens, 1).first.rotulo, 'SUPERSET');
    });

    test('cabeçalho do combinado', () {
      expect(
        cabecalhoDoCombinado(rotulo: 'BISET', tamanho: 2, voltas: 4, descansoSegundos: 90),
        'Bi-set · 4 voltas · descanso 90 s depois do último',
      );
      expect(cabecalhoDoCombinado(rotulo: null, tamanho: 3, voltas: 1, descansoSegundos: 0), 'Tri-set · 1 volta');
    });
  });

  group('execução dos métodos', () {
    test('bi-set: vai para o par sem descanso e descansa depois do último', () {
      final a = _exec(1, grupo: 1, feitas: 1);
      final b = _exec(2, grupo: 1);
      final depoisDeA = passoDoCombinado([a, b], a);
      expect(depoisDeA.focoId, 2);
      expect(depoisDeA.descansar, isFalse);

      final b1 = _exec(2, grupo: 1, feitas: 1);
      final depoisDeB = passoDoCombinado([a, b1], b1);
      expect(depoisDeB.focoId, 1); // próxima volta começa no primeiro
      expect(depoisDeB.descansar, isTrue);
    });

    test('sem combinado: descansa e não muda o foco', () {
      final r = passoDoCombinado([_exec(1)], _exec(1, feitas: 1));
      expect(r.focoId, isNull);
      expect(r.descansar, isTrue);
    });

    test('carga das quedas e passos do drop-set e do rest-pause', () {
      expect(cargaDaQueda(40, 1, 20), 32);
      expect(cargaDaQueda(40, 2, 20), 25.5);
      final drop = passosDoMetodo(
        const MetodoExercicio(tecnica: Tecnica.dropset, quedas: 2, reducaoPct: 20),
        cargaDaSerie: 40,
      );
      expect(drop.map((p) => p.titulo), ['Drop 1 · 32 kg', 'Drop 2 · 25,5 kg']);
      final rp = passosDoMetodo(const MetodoExercicio(tecnica: Tecnica.restpause, miniSeries: 2, pausaS: 15));
      expect(rp.length, 2);
      expect(rp.first.pausaS, 15);
      expect(passosDoMetodo(MetodoExercicio.normal), isEmpty);
    });
  });

  test('situação da ficha e iniciais na folha de aplicar', () {
    expect(situacaoDaFicha(RotinaFila.vazia), 'Sem ficha');
    expect(iniciais('Ana Clara Souza'), 'AS');
    expect(iniciais('Bia'), 'B');
  });
}
