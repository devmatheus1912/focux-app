import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/chat/data/chat_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/dashboard/data/aluno_autonomy_plan.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';

void main() {
  test(
    'prioriza perfil, medida e treino quando aluno ainda depende do personal',
    () {
      final plan = buildAlunoAutonomyPlan(
        aluno: Aluno(
          id: 1,
          nome: 'Matheus',
          email: 'm@focux.test',
          status: 'ATIVO',
        ),
        medidas: const [],
        treinos: [
          ExecucaoTreino(
            treinoId: 7,
            treinoNome: 'Treino A',
            status: 'PENDENTE',
            exercicios: const [],
          ),
        ],
        historico: const [],
        mensagens: const [],
        now: DateTime(2026, 4, 28),
      );

      expect(plan.profileCompletion, lessThan(60));
      expect(plan.nextTask?.id, 'perfil-base');
      expect(plan.tasks.where((task) => !task.done).length, greaterThan(4));
    },
  );

  test(
    'fecha pendencias principais quando aluno tem dados e rotina recente',
    () {
      final plan = buildAlunoAutonomyPlan(
        aluno: Aluno(
          id: 1,
          nome: 'Aluno Completo',
          email: 'aluno@focux.test',
          objetivo: 'Hipertrofia',
          status: 'ATIVO',
          fotoUrl: 'https://cdn.test/foto.jpg',
          telefone: '11999999999',
          whatsapp: '11999999999',
          genero: 'M',
          peso: 80,
          altura: 1.8,
          dataNascimento: '1995-01-10',
        ),
        medidas: [MedidaCorporal(id: 1, data: '2026-04-20', peso: 80)],
        treinos: [
          ExecucaoTreino(
            treinoId: 7,
            treinoNome: 'Treino A',
            status: 'CONCLUIDO',
            iniciadoEm: '2026-04-27T09:00:00',
            concluidoEm: '2026-04-27T10:00:00',
            exercicios: const [],
          ),
        ],
        historico: [
          ExecucaoTreino(
            treinoId: 7,
            treinoNome: 'Treino A',
            status: 'CONCLUIDO',
            iniciadoEm: '2026-04-27T09:00:00',
            concluidoEm: '2026-04-27T10:00:00',
            exercicios: const [],
          ),
        ],
        mensagens: [
          ChatMsg(
            remetente: 'ALUNO',
            conteudo: 'Treino concluido, senti pouca dor.',
            enviadoEm: DateTime(2026, 4, 27, 11),
          ),
        ],
        now: DateTime(2026, 4, 28),
      );

      expect(plan.profileCompletion, 100);
      expect(
        plan.tasks.firstWhere((task) => task.id == 'perfil-base').done,
        true,
      );
      expect(
        plan.tasks.firstWhere((task) => task.id == 'medida-recente').done,
        true,
      );
      expect(
        plan.tasks.firstWhere((task) => task.id == 'treino-semana').done,
        true,
      );
      expect(
        plan.tasks.firstWhere((task) => task.id == 'agenda-semana').done,
        false,
      );
    },
  );

  test('marca agenda-semana done quando agendaReviewed', () {
    final plan = buildAlunoAutonomyPlan(
      aluno: Aluno(
        id: 1,
        nome: 'Aluno Completo',
        email: 'aluno@focux.test',
        objetivo: 'Hipertrofia',
        status: 'ATIVO',
        fotoUrl: 'https://cdn.test/foto.jpg',
        telefone: '11999999999',
        whatsapp: '11999999999',
        genero: 'M',
        peso: 80,
        altura: 1.8,
        dataNascimento: '1995-01-10',
      ),
      medidas: [MedidaCorporal(id: 1, data: '2026-04-20', peso: 80)],
      treinos: const [],
      historico: const [],
      mensagens: const [],
      now: DateTime(2026, 4, 28),
      agendaReviewed: true,
    );

    expect(
      plan.tasks.firstWhere((task) => task.id == 'agenda-semana').done,
      true,
    );
  });

  test('home experience prioriza treino, score e narrativa proprietaria', () {
    final home = buildAlunoHomeExperience(
      aluno: Aluno(
        id: 1,
        nome: 'Thales Aluno',
        email: 'thales@focux.test',
        objetivo: 'Hipertrofia',
        status: 'ATIVO',
        fotoUrl: 'https://cdn.test/foto.jpg',
        telefone: '11999999999',
        whatsapp: '11999999999',
        genero: 'M',
        peso: 80,
        altura: 1.8,
        dataNascimento: '1995-01-10',
      ),
      medidas: [MedidaCorporal(id: 1, data: '2026-05-01', peso: 80)],
      treinos: [
        ExecucaoTreino(
          treinoId: 7,
          treinoNome: 'Treino A',
          status: 'DISPONIVEL',
          exercicios: [
            ExecucaoExercicio(
              id: 1,
              treinoExercicioId: 1,
              exercicioNome: 'Supino',
              seriesFeitas: 0,
              concluido: false,
            ),
          ],
        ),
      ],
      historico: [
        ExecucaoTreino(
          treinoId: 6,
          treinoNome: 'Treino B',
          status: 'CONCLUIDO',
          concluidoEm: '2026-05-03T10:00:00',
          exercicios: const [],
          evolucoesPerformance: const [
            EvolucaoPerformance(
              tipo: 'VOLUME',
              exercicioId: 1,
              exercicioNome: 'Supino',
              valorAnterior: 100,
              valorAtual: 120,
              diferenca: 20,
              unidade: 'kg',
              mensagem: 'Seu volume subiu 20% no Supino.',
            ),
          ],
        ),
      ],
      mensagens: [
        ChatMsg(
          remetente: 'ALUNO',
          conteudo: 'Treino bom.',
          enviadoEm: DateTime(2026, 5, 3, 11),
        ),
      ],
      now: DateTime(2026, 5, 5),
    );

    expect(home.action.mode, AlunoHomeMode.workoutReady);
    expect(home.action.title, 'Treino A');
    expect(home.action.cta, 'Treinar agora');
    expect(home.action.description, contains('1 exercícios'));
    expect(home.score.value, greaterThanOrEqualTo(70));
    expect(home.score.rhythmLabel, isNotEmpty);
    expect(home.objectiveLens.primaryMetric, 'volume e carga');
    expect(home.narratives.join(' '), contains('Treino A'));
    expect(home.narratives.join(' '), contains('Supino'));
  });

  test('workoutReady sem exercícios evita copy de 0 exercícios', () {
    final home = buildAlunoHomeExperience(
      aluno: Aluno(
        id: 1,
        nome: 'Thales Aluno',
        email: 'thales@focux.test',
        objetivo: 'Hipertrofia',
        status: 'ATIVO',
        fotoUrl: 'https://cdn.test/foto.jpg',
        telefone: '11999999999',
        whatsapp: '11999999999',
        genero: 'M',
        peso: 80,
        altura: 1.8,
        dataNascimento: '1995-01-10',
      ),
      medidas: [MedidaCorporal(id: 1, data: '2026-05-01', peso: 80)],
      treinos: [
        ExecucaoTreino(
          treinoId: 7,
          treinoNome: 'Treino A',
          status: 'DISPONIVEL',
          exercicios: const [],
        ),
      ],
      historico: [
        ExecucaoTreino(
          treinoId: 6,
          treinoNome: 'Treino B',
          status: 'CONCLUIDO',
          concluidoEm: '2026-05-03T10:00:00',
          exercicios: const [],
        ),
      ],
      mensagens: const [],
      now: DateTime(2026, 5, 5),
    );

    expect(home.action.mode, AlunoHomeMode.workoutReady);
    expect(home.action.description, isNot(contains('0 exercícios')));
    expect(
      home.action.description,
      'Sessão pronta para iniciar com registro de séries.',
    );
  });

  test('ficha aguardando liberacao nao oferece CTA de iniciar', () {
    final home = buildAlunoHomeExperience(
      aluno: Aluno(
        id: 1,
        nome: 'Aluno Espera',
        email: 'espera@focux.test',
        objetivo: 'Hipertrofia',
        status: 'ATIVO',
        fotoUrl: 'https://cdn.test/foto.jpg',
        telefone: '11999999999',
        whatsapp: '11999999999',
        genero: 'M',
        peso: 80,
        altura: 1.8,
        dataNascimento: '1995-01-10',
      ),
      medidas: [MedidaCorporal(id: 1, data: '2026-05-01', peso: 80)],
      treinos: [
        ExecucaoTreino(
          treinoId: 7,
          treinoNome: 'Treino A',
          status: 'AGUARDANDO_LIBERACAO',
          exercicios: const [],
        ),
      ],
      historico: const [],
      mensagens: const [],
      now: DateTime(2026, 5, 5),
    );

    expect(home.action.mode, AlunoHomeMode.awaitingRelease);
    expect(home.action.cta, isNot(contains('Treinar')));
    expect(home.action.route, '/checkin/treinos');
    expect(home.narratives.join(' '), contains('preparação'));
  });

  test('home experience troca prioridade quando aluno precisa retomar', () {
    final home = buildAlunoHomeExperience(
      aluno: Aluno(
        id: 1,
        nome: 'Aluno Retomada',
        email: 'retomada@focux.test',
        objetivo: 'Saúde',
        status: 'ATIVO',
        fotoUrl: 'https://cdn.test/foto.jpg',
        telefone: '11999999999',
        whatsapp: '11999999999',
        genero: 'F',
        peso: 70,
        altura: 1.65,
        dataNascimento: '1997-02-10',
      ),
      medidas: const [],
      treinos: [
        ExecucaoTreino(
          treinoId: 9,
          treinoNome: 'Treino Leve',
          status: 'DISPONIVEL',
          exercicios: [
            ExecucaoExercicio(
              id: 1,
              treinoExercicioId: 1,
              exercicioNome: 'Agachamento',
              seriesFeitas: 0,
              concluido: false,
            ),
          ],
        ),
      ],
      historico: [
        ExecucaoTreino(
          treinoId: 1,
          treinoNome: 'Treino Antigo',
          status: 'CONCLUIDO',
          concluidoEm: '2026-04-20T10:00:00',
          exercicios: const [],
        ),
      ],
      mensagens: const [],
      now: DateTime(2026, 5, 5),
    );

    expect(home.action.mode, AlunoHomeMode.comeback);
    expect(home.action.cta, 'Retomar agora');
    expect(home.objectiveLens.label, 'Saúde');
    expect(home.score.riskLabel, isNot('Risco baixo'));
  });
}
