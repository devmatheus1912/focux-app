import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';

final _hoje = DateTime(2026, 9, 27);

Aluno _aluno({bool completo = true, String? fotoUrl = 'https://cdn.test/f.jpg'}) =>
    Aluno(
      id: 1,
      nome: 'Ana',
      email: 'a@focux.test',
      status: 'ATIVO',
      fotoUrl: fotoUrl,
      telefone: '11999999999',
      objetivo: completo ? 'Hipertrofia' : null,
      genero: completo ? 'F' : null,
      peso: completo ? 62 : null,
      altura: completo ? 1.65 : null,
      dataNascimento: completo ? '1995-01-10' : null,
    );

MedidaCorporal _medida(DateTime data) => MedidaCorporal(
  id: 1,
  data:
      '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
  peso: 62,
);

List<AlunoPendenciaTipo> _tipos(List<AlunoPendencia> list) =>
    list.map((p) => p.tipo).toList();

void main() {
  group('resolveAlunoPendencias', () {
    test('tudo em dia → lista vazia', () {
      final list = resolveAlunoPendencias(
        aluno: _aluno(),
        medidas: [_medida(_hoje)],
        naoLidasDoPersonal: 0,
        agendaReviewed: true,
        todayMode: AlunoTodayMode.workoutReady,
        now: _hoje,
      );
      expect(list, isEmpty);
    });

    test('ordem de prioridade e corte em 3', () {
      final list = resolveAlunoPendencias(
        aluno: _aluno(completo: false, fotoUrl: null),
        medidas: const [],
        naoLidasDoPersonal: 2,
        agendaReviewed: false,
        todayMode: AlunoTodayMode.workoutReady,
        now: _hoje,
      );
      expect(_tipos(list), [
        AlunoPendenciaTipo.perfil,
        AlunoPendenciaTipo.foto,
        AlunoPendenciaTipo.medida,
      ]);
    });

    test('não repete o P0 de perfil', () {
      final list = resolveAlunoPendencias(
        aluno: _aluno(completo: false),
        medidas: [_medida(_hoje)],
        naoLidasDoPersonal: 1,
        agendaReviewed: false,
        todayMode: AlunoTodayMode.profileSetup,
        now: _hoje,
      );
      expect(_tipos(list), [AlunoPendenciaTipo.chat, AlunoPendenciaTipo.agenda]);
    });

    test('medida vale por 14 dias', () {
      List<AlunoPendenciaTipo> comMedidaDe(int dias) => _tipos(
        resolveAlunoPendencias(
          aluno: _aluno(),
          medidas: [_medida(_hoje.subtract(Duration(days: dias)))],
          naoLidasDoPersonal: 0,
          agendaReviewed: true,
          todayMode: AlunoTodayMode.workoutReady,
          now: _hoje,
        ),
      );
      expect(comMedidaDe(14), isEmpty);
      expect(comMedidaDe(15), [AlunoPendenciaTipo.medida]);
    });

    test('chat só com mensagem do personal não lida', () {
      List<AlunoPendenciaTipo> comNaoLidas(int n) => _tipos(
        resolveAlunoPendencias(
          aluno: _aluno(),
          medidas: [_medida(_hoje)],
          naoLidasDoPersonal: n,
          agendaReviewed: true,
          todayMode: AlunoTodayMode.workoutReady,
          now: _hoje,
        ),
      );
      expect(comNaoLidas(0), isEmpty);
      expect(comNaoLidas(1), [AlunoPendenciaTipo.chat]);
    });

    test('mantém os taskId do contrato de autonomia', () {
      expect(AlunoPendenciaTipo.perfil.taskId, 'perfil-base');
      expect(AlunoPendenciaTipo.foto.taskId, 'foto-dados');
      expect(AlunoPendenciaTipo.medida.taskId, 'medida-recente');
      expect(AlunoPendenciaTipo.chat.taskId, 'chat-contexto');
      expect(AlunoPendenciaTipo.agenda.taskId, 'agenda-semana');
      expect(AlunoPendenciaTipo.agenda.route, '/agenda/aluno');
      expect(AlunoPendenciaTipo.chat.route, '/chat/aluno');
    });
  });

  group('resolveAlunoHomeAviso', () {
    test('anamnese vence o coach', () {
      expect(
        resolveAlunoHomeAviso(anamnesePendente: true, coachMensagens: 2),
        AlunoHomeAviso.anamnese,
      );
    });

    test('só coach', () {
      expect(
        resolveAlunoHomeAviso(anamnesePendente: false, coachMensagens: 1),
        AlunoHomeAviso.coach,
      );
    });

    test('nenhum', () {
      expect(
        resolveAlunoHomeAviso(anamnesePendente: false, coachMensagens: 0),
        AlunoHomeAviso.nenhum,
      );
    });
  });
}
