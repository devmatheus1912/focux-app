import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/treinos_hub_view.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';

final _agora = DateTime(2026, 9, 27, 18);

ExecucaoTreino _ficha(
  int id,
  String nome, {
  String status = 'DISPONIVEL',
  int exercicios = 6,
}) => ExecucaoTreino(
  treinoId: id,
  treinoNome: nome,
  status: status,
  exercicios: const [],
  exerciciosCount: exercicios,
);

ExecucaoTreino _exec(
  int id,
  int treinoId, {
  String status = 'CONCLUIDO',
  String? iniciadoEm,
  String? concluidoEm,
  int? concluidos,
}) => ExecucaoTreino(
  id: id,
  treinoId: treinoId,
  treinoNome: 'Treino $treinoId',
  status: status,
  iniciadoEm: iniciadoEm,
  concluidoEm: concluidoEm,
  exercicios: const [],
  exerciciosConcluidos: concluidos,
);

TreinosHubView _view(
  List<ExecucaoTreino> treinos, [
  List<ExecucaoTreino> historico = const [],
]) => buildTreinosHubView(treinos: treinos, historico: historico, now: _agora);

void main() {
  final a = _ficha(1, 'Treino A');
  final b = _ficha(2, 'Treino B');
  final c = _ficha(3, 'Treino C');

  group('destaque', () {
    test('em andamento vence tudo e traz N de M', () {
      final v = _view(
        [a, _ficha(2, 'Treino B', status: 'EM_ANDAMENTO'), c],
        [
          _exec(90, 2, status: 'EM_ANDAMENTO', concluidos: 4),
          _exec(80, 1, concluidoEm: '2026-09-27T07:00:00'),
        ],
      );
      expect(v.destaque!.tipo, TreinosDestaqueTipo.emAndamento);
      expect(v.destaque!.treino.treinoId, 2);
      expect(v.destaque!.exerciciosFeitos, 4);
      expect(v.destaque!.treino.totalExercicios, 6);
      expect(v.depois, isNull);
    });

    test('em andamento sem item no histórico não inventa N', () {
      final v = _view([_ficha(2, 'Treino B', status: 'EM_ANDAMENTO')]);
      expect(v.destaque!.exerciciosFeitos, isNull);
    });

    test('concluído hoje traz duração e o próximo em Depois', () {
      final v = _view(
        [a, b, c],
        [
          _exec(
            80,
            1,
            iniciadoEm: '2026-09-27T07:00:00',
            concluidoEm: '2026-09-27T07:52:00',
          ),
        ],
      );
      expect(v.destaque!.tipo, TreinosDestaqueTipo.concluidoHoje);
      expect(v.destaque!.treino.id, 80);
      expect(v.destaque!.duracao, const Duration(minutes: 52));
      expect(v.depois!.treinoId, 2);
      expect(v.plano.map((t) => t.treinoId), [3]);
    });

    test('treino de ontem volta ao próximo, sem Depois', () {
      final v = _view([a, b], [_exec(80, 1, concluidoEm: '2026-09-26T19:00')]);
      expect(v.destaque!.tipo, TreinosDestaqueTipo.proximo);
      expect(v.destaque!.treino.treinoId, 2);
      expect(v.depois, isNull);
      expect(v.plano.map((t) => t.treinoId), [1]);
    });

    test('sem histórico o próximo é a primeira ficha do rodízio', () {
      final v = _view([a, b, c]);
      expect(v.destaque!.tipo, TreinosDestaqueTipo.proximo);
      expect(v.destaque!.treino.treinoId, 1);
      expect(v.plano.map((t) => t.treinoId), [2, 3]);
    });

    test('só fichas em preparação viram destaque sem ação', () {
      final v = _view([
        _ficha(1, 'Treino A', status: 'AGUARDANDO_LIBERACAO', exercicios: 0),
        _ficha(2, 'Treino B', status: 'AGUARDANDO_LIBERACAO', exercicios: 0),
      ]);
      expect(v.destaque!.tipo, TreinosDestaqueTipo.emPreparacao);
      expect(v.destaque!.treino.treinoId, 1);
      expect(v.plano.map((t) => t.treinoId), [2]);
    });

    test('sem fichas não há destaque nem plano', () {
      final v = _view(const []);
      expect(v.destaque, isNull);
      expect(v.plano, isEmpty);
    });

    test('próximo do hub é o mesmo do foco da Home', () {
      final historico = [_exec(80, 2, concluidoEm: '2026-09-25T10:00:00')];
      final treinos = [a, b, c];
      final hub = _view(treinos, historico);
      final home = resolveAlunoTodayAction(
        aluno: Aluno(id: 1, nome: 'Ana', email: 'a@t.com', status: 'ATIVO'),
        treinos: treinos,
        historico: historico,
        now: _agora,
      );
      expect(hub.destaque!.treino.treinoId, home.routeExtra);
      expect(hub.destaque!.treino.totalExercicios, home.exerciseCount);
    });
  });

  group('últimos treinos', () {
    test('até 3 concluídos, mais recente primeiro, sem o destaque', () {
      final v = _view(
        [a, b],
        [
          _exec(5, 1, concluidoEm: '2026-09-27T07:30:00'),
          _exec(4, 2, status: 'EM_ANDAMENTO'),
          _exec(3, 2, concluidoEm: '2026-09-22T10:00:00'),
          _exec(1, 1, concluidoEm: '2026-09-20T10:00:00'),
          _exec(2, 2, concluidoEm: '2026-09-25T10:00:00'),
          _exec(0, 1, concluidoEm: '2026-09-18T10:00:00'),
        ],
      );
      expect(v.destaque!.treino.id, 5);
      expect(v.ultimos.map((u) => u.execucao.id), [2, 3, 1]);
    });

    test('sem histórico a lista fica vazia', () {
      expect(_view([a]).ultimos, isEmpty);
    });

    test('registro sem séries fica com zero concluídos e sem duração', () {
      final v = _view(
        [a],
        [
          _exec(
            7,
            1,
            iniciadoEm: '2026-09-20T10:00:00',
            concluidoEm: '2026-09-20T10:00:01',
            concluidos: 0,
          ),
        ],
      );
      expect(v.ultimos.single.duracao, isNull);
      expect(v.ultimos.single.exerciciosConcluidos, 0);
    });
  });

  group('treinoDuracaoReal', () {
    test('entre 5 min e 8 h aparece', () {
      expect(
        treinoDuracaoReal('2026-09-27T07:00:00', '2026-09-27T07:05:00'),
        const Duration(minutes: 5),
      );
      expect(
        treinoDuracaoReal('2026-09-27T07:00:00', '2026-09-27T15:00:00'),
        const Duration(hours: 8),
      );
    });

    test('fora da faixa ou sem data some', () {
      expect(
        treinoDuracaoReal('2026-09-27T07:00:00', '2026-09-27T07:04:59'),
        isNull,
      );
      expect(
        treinoDuracaoReal('2026-09-27T07:00:00', '2026-09-27T15:00:01'),
        isNull,
      );
      expect(treinoDuracaoReal(null, '2026-09-27T07:00:00'), isNull);
      expect(treinoDuracaoReal('2026-09-27T07:00:00', null), isNull);
    });
  });

  test('vale até a meia-noite seguinte', () {
    expect(_view([a]).validaAte, DateTime(2026, 9, 28));
  });
}
