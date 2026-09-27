import '../../alunos/data/aluno_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/treino_ficha_status.dart';
import '../../treinos/utils/treino_atribuicao_prazo.dart';

/// Ação principal (P0) do card "Hoje" do aluno, em ordem de prioridade.
enum AlunoTodayMode {
  financialHold,
  workoutReady,
  awaitingRelease,
  profileSetup,
  noWorkout,
}

class AlunoTodayAction {
  final AlunoTodayMode mode;
  final String route;
  final Object? routeExtra;
  final String? treinoNome;
  final int exerciseCount;

  /// Treino pronto depois de 7+ dias sem treinar (dias de calendário do servidor).
  final bool comeback;
  final DateTime? prazoFim;

  const AlunoTodayAction({
    required this.mode,
    required this.route,
    this.routeExtra,
    this.treinoNome,
    this.exerciseCount = 0,
    this.comeback = false,
    this.prazoFim,
  });
}

const alunoComebackDias = 7;
const alunoPerfilMinimoP0 = 60;

AlunoTodayAction resolveAlunoTodayAction({
  required Aluno aluno,
  required List<ExecucaoTreino> treinos,
  List<ExecucaoTreino> historico = const [],
}) {
  if (aluno.inadimplente) {
    return const AlunoTodayAction(
      mode: AlunoTodayMode.financialHold,
      route: '/financeiro/aluno',
    );
  }

  final proximo = proximoTreinoParaHoje(treinos: treinos, historico: historico);
  if (proximo != null) {
    return AlunoTodayAction(
      mode: AlunoTodayMode.workoutReady,
      route: '/checkin/executar',
      routeExtra: proximo.treinoId,
      treinoNome: proximo.treinoNome,
      exerciseCount: proximo.exercicios.length,
      comeback: (aluno.diasSemTreino ?? 0) >= alunoComebackDias,
      prazoFim: TreinoAtribuicaoPrazo.parseIsoDate(proximo.dataFim),
    );
  }

  for (final treino in treinos) {
    if (isTreinoAguardandoLiberacao(treino)) {
      return AlunoTodayAction(
        mode: AlunoTodayMode.awaitingRelease,
        route: '/checkin/treinos',
        treinoNome: treino.treinoNome,
      );
    }
  }

  if (alunoProfileCompletion(aluno) < alunoPerfilMinimoP0) {
    return const AlunoTodayAction(
      mode: AlunoTodayMode.profileSetup,
      route: '/aluno/perfil',
    );
  }

  return const AlunoTodayAction(
    mode: AlunoTodayMode.noWorkout,
    route: '/chat/aluno',
  );
}

/// Completude do perfil (0–100). Telefone e WhatsApp contam como um contato.
int alunoProfileCompletion(Aluno aluno) {
  final campos = [
    _filled(aluno.telefone) || _filled(aluno.whatsapp),
    _filled(aluno.objetivo),
    _filled(aluno.genero),
    aluno.peso != null,
    aluno.altura != null,
    _filled(aluno.dataNascimento),
  ];
  final preenchidos = campos.where((c) => c).length;
  return ((preenchidos / campos.length) * 100).round();
}

/// `taskId` do contrato de autonomia quando o toque no P0 pede ação do personal.
String? alunoAutonomyTaskIdForToday(AlunoTodayMode mode) => switch (mode) {
  AlunoTodayMode.financialHold => 'financeiro',
  AlunoTodayMode.noWorkout => 'treino-semana',
  AlunoTodayMode.profileSetup => 'perfil-base',
  AlunoTodayMode.workoutReady || AlunoTodayMode.awaitingRelease => null,
};

bool _filled(String? value) => value != null && value.trim().isNotEmpty;
