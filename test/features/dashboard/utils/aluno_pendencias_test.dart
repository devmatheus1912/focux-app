import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_anamnese.dart';
import 'package:focux_app/features/dashboard/screens/perfil_aluno_editar_screen.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';

final _hoje = DateTime(2026, 9, 27);
final _horario = DateTime(2026, 9, 30, 18);

Aluno _aluno({
  bool completo = true,
  String? fotoUrl = 'https://cdn.test/f.jpg',
}) => Aluno(
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
  group('listAlunoPendenciasAbertas', () {
    test('tudo em dia → lista vazia', () {
      final list = listAlunoPendenciasAbertas(
        aluno: _aluno(),
        medidas: [_medida(_hoje)],
        naoLidasDoPersonal: 0,
        agendaProximoInicio: _horario,
        agendaReviewed: true,
        todayMode: AlunoTodayMode.workoutReady,
        now: _hoje,
      );
      expect(list, isEmpty);
    });

    test('urgência: chat, agenda, medida, cadastro', () {
      final list = listAlunoPendenciasAbertas(
        aluno: _aluno(completo: false, fotoUrl: null),
        medidas: const [],
        naoLidasDoPersonal: 2,
        agendaProximoInicio: _horario,
        agendaReviewed: false,
        todayMode: AlunoTodayMode.workoutReady,
        now: _hoje,
      );
      expect(_tipos(list), [
        AlunoPendenciaTipo.chat,
        AlunoPendenciaTipo.agenda,
        AlunoPendenciaTipo.medida,
        AlunoPendenciaTipo.perfil,
      ]);
      expect(list.first.quantidade, 2);
    });

    test('perfil e foto viram 1 item; só a foto falta abre o seletor', () {
      List<AlunoPendenciaTipo> cadastro(Aluno a) => _tipos(
        listAlunoPendenciasAbertas(
          aluno: a,
          medidas: [_medida(_hoje)],
          naoLidasDoPersonal: 0,
          agendaProximoInicio: null,
          agendaReviewed: true,
          todayMode: AlunoTodayMode.workoutReady,
          now: _hoje,
        ),
      );
      expect(cadastro(_aluno(completo: false, fotoUrl: null)), [
        AlunoPendenciaTipo.perfil,
      ]);
      expect(cadastro(_aluno(fotoUrl: null)), [AlunoPendenciaTipo.foto]);
    });

    test('não repete o P0 de perfil', () {
      final list = listAlunoPendenciasAbertas(
        aluno: _aluno(completo: false, fotoUrl: null),
        medidas: [_medida(_hoje)],
        naoLidasDoPersonal: 1,
        agendaProximoInicio: _horario,
        agendaReviewed: false,
        todayMode: AlunoTodayMode.profileSetup,
        now: _hoje,
      );
      expect(_tipos(list), [
        AlunoPendenciaTipo.chat,
        AlunoPendenciaTipo.agenda,
      ]);
    });

    test('agenda hoje ou amanhã fica no foco; depois vira pendência', () {
      List<AlunoPendencia> agenda(DateTime? inicio) =>
          listAlunoPendenciasAbertas(
            aluno: _aluno(),
            medidas: [_medida(_hoje)],
            naoLidasDoPersonal: 0,
            agendaProximoInicio: inicio,
            agendaReviewed: false,
            todayMode: AlunoTodayMode.workoutReady,
            now: _hoje,
          );
      expect(agenda(null), isEmpty);
      expect(agenda(DateTime(2026, 9, 27, 18)), isEmpty);
      expect(agenda(DateTime(2026, 9, 28, 7, 30)), isEmpty);
      final list = agenda(_horario);
      expect(_tipos(list), [AlunoPendenciaTipo.agenda]);
      expect(list.single.quando, _horario);
    });

    test('medida vale por 14 dias', () {
      List<AlunoPendenciaTipo> comMedidaDe(int dias) => _tipos(
        listAlunoPendenciasAbertas(
          aluno: _aluno(),
          medidas: [_medida(_hoje.subtract(Duration(days: dias)))],
          naoLidasDoPersonal: 0,
          agendaProximoInicio: _horario,
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
        listAlunoPendenciasAbertas(
          aluno: _aluno(),
          medidas: [_medida(_hoje)],
          naoLidasDoPersonal: n,
          agendaProximoInicio: _horario,
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
      expect(AlunoPendenciaTipo.agenda.taskTitlePt, 'Conferir próximo horário');
    });

    test('perfil, foto e medida abrem direto no editor', () {
      expect(AlunoPendenciaTipo.perfil.route, '/aluno/perfil/editar');
      PerfilEditarAcao? acao(AlunoPendenciaTipo t) =>
          PerfilEditarAcao.tryParse(Uri.parse(t.route).queryParameters['acao']);
      expect(acao(AlunoPendenciaTipo.foto), PerfilEditarAcao.foto);
      expect(acao(AlunoPendenciaTipo.medida), PerfilEditarAcao.medida);
      expect(acao(AlunoPendenciaTipo.perfil), isNull);
      expect(PerfilEditarAcao.tryParse('x'), isNull);
    });
  });

  group('alunoPendenciasVisiveis', () {
    const todas = [
      AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: 1),
      AlunoPendencia(AlunoPendenciaTipo.agenda),
      AlunoPendencia(AlunoPendenciaTipo.medida),
      AlunoPendencia(AlunoPendenciaTipo.foto),
    ];

    test('sem treino o foco já é o chat: pendência de chat sai', () {
      expect(_tipos(alunoPendenciasVisiveis(todas, AlunoTodayMode.noWorkout)), [
        AlunoPendenciaTipo.agenda,
        AlunoPendenciaTipo.medida,
        AlunoPendenciaTipo.foto,
      ]);
    });

    test('com treino mantém o chat e corta em 3', () {
      expect(
        _tipos(alunoPendenciasVisiveis(todas, AlunoTodayMode.workoutReady)),
        [
          AlunoPendenciaTipo.chat,
          AlunoPendenciaTipo.agenda,
          AlunoPendenciaTipo.medida,
        ],
      );
    });
  });

  group('resolveAlunoHomeAviso', () {
    AlunoHomeAviso aviso({
      bool inadimplente = false,
      AlunoAnamnesePendente? anamnese,
      int coach = 0,
    }) => resolveAlunoHomeAviso(
      inadimplente: inadimplente,
      anamnese: anamnese,
      coachMensagens: coach,
    );

    test('saúde antes de dinheiro: atestado vence a mensalidade', () {
      expect(
        aviso(
          inadimplente: true,
          anamnese: AlunoAnamnesePendente.precisaAtestado,
          coach: 2,
        ),
        AlunoHomeAviso.atestado,
      );
    });

    test('mensalidade vence anamnese solicitada e coach', () {
      expect(
        aviso(
          inadimplente: true,
          anamnese: AlunoAnamnesePendente.solicitada,
          coach: 2,
        ),
        AlunoHomeAviso.financeiro,
      );
    });

    test('anamnese solicitada vence o coach', () {
      expect(
        aviso(anamnese: AlunoAnamnesePendente.solicitada, coach: 2),
        AlunoHomeAviso.anamnese,
      );
    });

    test('só coach', () {
      expect(aviso(coach: 1), AlunoHomeAviso.coach);
    });

    test('nenhum', () {
      expect(aviso(), AlunoHomeAviso.nenhum);
    });
  });
}
