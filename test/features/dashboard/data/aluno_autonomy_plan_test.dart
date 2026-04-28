import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/chat/data/chat_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/dashboard/data/aluno_autonomy_plan.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';

void main() {
  test('prioriza perfil, medida e treino quando aluno ainda depende do personal', () {
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
  });

  test('fecha pendencias principais quando aluno tem dados e rotina recente', () {
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
      medidas: [
        MedidaCorporal(
          id: 1,
          data: '2026-04-20',
          peso: 80,
        ),
      ],
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
    expect(plan.tasks.firstWhere((task) => task.id == 'perfil-base').done, true);
    expect(plan.tasks.firstWhere((task) => task.id == 'medida-recente').done, true);
    expect(plan.tasks.firstWhere((task) => task.id == 'treino-semana').done, true);
  });
}
