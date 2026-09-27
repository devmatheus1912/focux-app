import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';

Aluno _aluno({
  bool inadimplente = false,
  String? fotoUrl,
  int? diasSemTreino,
  bool perfilCompleto = true,
}) => Aluno(
  id: 1,
  nome: 'Ana Souza',
  email: 'ana@focux.test',
  status: 'ATIVO',
  inadimplente: inadimplente,
  fotoUrl: fotoUrl,
  diasSemTreino: diasSemTreino,
  telefone: perfilCompleto ? '11999999999' : null,
  objetivo: perfilCompleto ? 'Hipertrofia' : null,
  genero: perfilCompleto ? 'F' : null,
  peso: perfilCompleto ? 62 : null,
  altura: perfilCompleto ? 1.65 : null,
  dataNascimento: perfilCompleto ? '1995-01-10' : null,
);

ExecucaoTreino _treino(
  int id,
  String nome, {
  String status = 'DISPONIVEL',
  int exercicios = 1,
  String? dataFim,
}) => ExecucaoTreino(
  treinoId: id,
  treinoNome: nome,
  status: status,
  dataFim: dataFim,
  exercicios: [
    for (var i = 0; i < exercicios; i++)
      ExecucaoExercicio(
        id: id * 10 + i,
        treinoExercicioId: id * 10 + i,
        exercicioNome: 'Exercício $i',
        seriesFeitas: 0,
        concluido: false,
      ),
  ],
);

void main() {
  group('resolveAlunoTodayAction', () {
    test('mensalidade atrasada não tira o treino do foco', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(inadimplente: true),
        treinos: [_treino(7, 'Treino A')],
      );
      expect(a.mode, AlunoTodayMode.workoutReady);
      expect(a.route, '/checkin/executar');
    });

    test('treino pronto vira o P0 mesmo sem foto de perfil', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(),
        treinos: [_treino(7, 'Treino A', exercicios: 3)],
      );
      expect(a.mode, AlunoTodayMode.workoutReady);
      expect(a.route, '/checkin/executar');
      expect(a.routeExtra, 7);
      expect(a.treinoNome, 'Treino A');
      expect(a.exerciseCount, 3);
      expect(a.comeback, isFalse);
    });

    test('treino pronto vence perfil incompleto', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(perfilCompleto: false),
        treinos: [_treino(7, 'Treino A')],
      );
      expect(a.mode, AlunoTodayMode.workoutReady);
    });

    test('retomada só a partir de 7 dias sem treino', () {
      final seis = resolveAlunoTodayAction(
        aluno: _aluno(diasSemTreino: 6),
        treinos: [_treino(7, 'Treino A')],
      );
      final sete = resolveAlunoTodayAction(
        aluno: _aluno(diasSemTreino: 7),
        treinos: [_treino(7, 'Treino A')],
      );
      expect(seis.comeback, isFalse);
      expect(sete.comeback, isTrue);
      expect(sete.mode, AlunoTodayMode.workoutReady);
    });

    test('leva o prazo da atribuição', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(),
        treinos: [_treino(7, 'Treino A', dataFim: '2026-10-01')],
      );
      expect(a.prazoFim, DateTime(2026, 10, 1));
    });

    test('não gruda no Treino A depois de concluir A', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(),
        treinos: [_treino(7, 'Treino A'), _treino(8, 'Treino B')],
        historico: [
          ExecucaoTreino(
            treinoId: 7,
            treinoNome: 'Treino A',
            status: 'CONCLUIDO',
            concluidoEm: '2026-05-04T10:00:00',
            exercicios: const [],
          ),
        ],
      );
      expect(a.treinoNome, 'Treino B');
      expect(a.routeExtra, 8);
    });

    group('treino de hoje feito', () {
      final agora = DateTime(2026, 9, 27, 18);
      ExecucaoTreino feito(String quando, {int id = 50}) => ExecucaoTreino(
        id: id,
        treinoId: 7,
        treinoNome: 'Treino A',
        status: 'CONCLUIDO',
        concluidoEm: quando,
        exercicios: const [],
      );
      final fichas = [_treino(7, 'Treino A'), _treino(8, 'Treino B')];

      test('não manda treinar de novo; mostra o feito e o próximo', () {
        final a = resolveAlunoTodayAction(
          aluno: _aluno(),
          treinos: fichas,
          historico: [feito('2026-09-27T07:30:00')],
          now: agora,
        );
        expect(a.mode, AlunoTodayMode.workoutDone);
        expect(a.treinoNome, 'Treino A');
        expect(a.proximoTreinoNome, 'Treino B');
        expect(a.route, '/checkin/historico/50');
      });

      test('treino de ontem volta a oferecer o próximo', () {
        final a = resolveAlunoTodayAction(
          aluno: _aluno(),
          treinos: fichas,
          historico: [feito('2026-09-26T19:00:00')],
          now: agora,
        );
        expect(a.mode, AlunoTodayMode.workoutReady);
        expect(a.treinoNome, 'Treino B');
      });

      test('sessão em andamento vence o feito de hoje', () {
        final a = resolveAlunoTodayAction(
          aluno: _aluno(),
          treinos: [
            _treino(7, 'Treino A'),
            _treino(8, 'Treino B', status: 'EM_ANDAMENTO'),
          ],
          historico: [feito('2026-09-27T07:30:00')],
          now: agora,
        );
        expect(a.mode, AlunoTodayMode.workoutReady);
        expect(a.treinoNome, 'Treino B');
      });

      test('mensalidade atrasada ainda mostra o treino feito hoje', () {
        final a = resolveAlunoTodayAction(
          aluno: _aluno(inadimplente: true),
          treinos: fichas,
          historico: [feito('2026-09-27T07:30:00')],
          now: agora,
        );
        expect(a.mode, AlunoTodayMode.workoutDone);
      });
    });

    test('retoma EM_ANDAMENTO antes de girar', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(),
        treinos: [
          _treino(7, 'Treino A'),
          _treino(9, 'Treino C', status: 'EM_ANDAMENTO'),
          _treino(8, 'Treino B'),
        ],
      );
      expect(a.treinoNome, 'Treino C');
      expect(a.routeExtra, 9);
    });

    test('ficha aguardando liberação não oferece iniciar', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(),
        treinos: [_treino(7, 'Treino A', status: 'AGUARDANDO_LIBERACAO')],
      );
      expect(a.mode, AlunoTodayMode.awaitingRelease);
      expect(a.route, '/checkin/treinos');
      expect(a.treinoNome, 'Treino A');
    });

    test('sem treino e perfil abaixo de 60% pede perfil', () {
      final a = resolveAlunoTodayAction(
        aluno: _aluno(perfilCompleto: false),
        treinos: const [],
      );
      expect(a.mode, AlunoTodayMode.profileSetup);
      expect(a.route, '/aluno/perfil/editar');
    });

    test('sem treino e perfil ok pede treino ao personal', () {
      final a = resolveAlunoTodayAction(aluno: _aluno(), treinos: const []);
      expect(a.mode, AlunoTodayMode.noWorkout);
      expect(a.route, '/chat/aluno');
    });
  });

  group('alunoProfileCompletion', () {
    test('telefone e WhatsApp contam como um campo de contato', () {
      final soTelefone = Aluno(
        id: 1,
        nome: 'Ana',
        email: 'a@focux.test',
        status: 'ATIVO',
        telefone: '11999999999',
      );
      final ambos = Aluno(
        id: 1,
        nome: 'Ana',
        email: 'a@focux.test',
        status: 'ATIVO',
        telefone: '11999999999',
        whatsapp: '11999999999',
      );
      expect(alunoProfileCompletion(soTelefone), 17);
      expect(alunoProfileCompletion(ambos), 17);
    });

    test('perfil completo é 100', () {
      expect(alunoProfileCompletion(_aluno()), 100);
    });
  });

  group('alunoAutonomyTaskIdForToday', () {
    test('só manda evento onde o personal precisa agir', () {
      expect(
        alunoAutonomyTaskIdForToday(AlunoTodayMode.noWorkout),
        'treino-semana',
      );
      expect(
        alunoAutonomyTaskIdForToday(AlunoTodayMode.profileSetup),
        'perfil-base',
      );
      expect(alunoAutonomyTaskIdForToday(AlunoTodayMode.workoutReady), isNull);
      expect(alunoAutonomyTaskIdForToday(AlunoTodayMode.workoutDone), isNull);
      expect(
        alunoAutonomyTaskIdForToday(AlunoTodayMode.awaitingRelease),
        isNull,
      );
    });
  });
}
