import '../../alunos/data/aluno_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/rotina_decisao.dart';
import '../../checkin/utils/treino_ficha_status.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/treino_atribuicao_prazo.dart';

/// Ação principal (P0) do card "Hoje" do aluno, em ordem de prioridade.
/// Mensalidade atrasada não bloqueia treino: é aviso ([AlunoHomeAviso]), não modo.
enum AlunoTodayMode {
  workoutDone,
  workoutReady,
  descansoHoje,
  awaitingRelease,
  profileSetup,
  noWorkout,
}

class AlunoTodayAction {
  final AlunoTodayMode mode;
  final String route;
  final Object? routeExtra;
  final String? treinoNome;

  /// Treino feito hoje: a próxima ficha do rodízio, só como prévia.
  final String? proximoTreinoNome;

  /// Próxima ficha para "Fazer mais um".
  final int? proximoTreinoId;

  /// Posição do treino de agora na fila (1-based) e tamanho da fila.
  final int ordem;
  final int ordemTotal;
  final String? depoisNome;

  /// O item seguinte da fila é um descanso: a frase muda, o treino não trava.
  final bool proximoEhDescanso;

  /// Sessão aberta. A Home usa a mesma frase da aba Treinos.
  final bool continuar;
  final int? exerciciosFeitos;
  final int exerciseCount;

  /// Treino pronto depois de 7+ dias sem treinar (dias de calendário do servidor).
  final bool comeback;
  final DateTime? prazoFim;

  const AlunoTodayAction({
    required this.mode,
    required this.route,
    this.routeExtra,
    this.treinoNome,
    this.proximoTreinoNome,
    this.proximoTreinoId,
    this.ordem = 0,
    this.ordemTotal = 0,
    this.depoisNome,
    this.proximoEhDescanso = false,
    this.continuar = false,
    this.exerciciosFeitos,
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
  RotinaFila? rotina,
  DateTime? now,
}) {
  final agora = now ?? DateTime.now();
  if (rotina != null && rotina.itens.isNotEmpty) {
    final decisao = decisaoDaRotina(
      itens: rotina.itens,
      diasAviso: rotina.diasAviso,
      treinos: treinos,
      historico: historico,
      agora: agora,
    );
    if (decisao != null) {
      return acaoDaDecisao(
        decisao,
        comeback: (aluno.diasSemTreino ?? 0) >= alunoComebackDias,
      );
    }
  }
  final proximo = proximoTreinoParaHoje(treinos: treinos, historico: historico);
  final feitoHoje =
      treinoSessaoEmAndamento(treinos) == null
          ? treinoConcluidoHoje(historico, now: now)
          : null;
  if (feitoHoje != null) {
    final id = feitoHoje.id;
    return AlunoTodayAction(
      mode: AlunoTodayMode.workoutDone,
      route: id == null ? '/checkin/historico' : '/checkin/historico/$id',
      treinoNome: feitoHoje.treinoNome,
      proximoTreinoNome: proximo?.treinoNome,
      proximoTreinoId: proximo?.treinoId,
    );
  }
  if (proximo != null) {
    final fila = treinosProntosParaIniciar(treinos);
    final idx = fila.indexWhere((t) => t.treinoId == proximo.treinoId);
    final depois = fila.length > 1 ? fila[(idx + 1) % fila.length] : null;
    final continuar =
        normalizeTreinoStatus(proximo.status) == treinoStatusEmAndamento;
    return AlunoTodayAction(
      mode: AlunoTodayMode.workoutReady,
      route: '/checkin/executar',
      routeExtra: proximo.treinoId,
      treinoNome: proximo.treinoNome,
      exerciseCount: proximo.totalExercicios,
      ordem: idx < 0 ? 1 : idx + 1,
      ordemTotal: fila.length,
      depoisNome: depois?.treinoNome,
      continuar: continuar,
      exerciciosFeitos: continuar ? _feitosDaSessao(historico, proximo.treinoId) : null,
      comeback: !continuar && (aluno.diasSemTreino ?? 0) >= alunoComebackDias,
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
      route: '/aluno/perfil/editar',
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
  AlunoTodayMode.noWorkout => 'treino-semana',
  AlunoTodayMode.profileSetup => 'perfil-base',
  AlunoTodayMode.workoutDone ||
  AlunoTodayMode.workoutReady ||
  AlunoTodayMode.descansoHoje ||
  AlunoTodayMode.awaitingRelease => null,
};

AlunoTodayAction acaoDaDecisao(RotinaDecisao decisao, {bool comeback = false}) {
  final foco = decisao.foco;
  return switch (decisao.momento) {
    RotinaMomento.continuar => AlunoTodayAction(
      mode: AlunoTodayMode.workoutReady,
      route: '/checkin/executar',
      routeExtra: foco.treinoId,
      treinoNome: foco.treinoNome,
      exerciseCount: foco.totalExercicios,
      continuar: true,
      exerciciosFeitos: decisao.exerciciosFeitos,
      ordem: decisao.ordem,
      ordemTotal: decisao.ordemTotal,
      depoisNome: decisao.depoisNome,
    ),
    RotinaMomento.pronto => AlunoTodayAction(
      mode: AlunoTodayMode.workoutDone,
      route: foco.id == null ? '/checkin/historico' : '/checkin/historico/${foco.id}',
      treinoNome: foco.treinoNome,
      proximoTreinoNome: decisao.depoisNome,
      proximoTreinoId: decisao.depois?.treinoId,
      proximoEhDescanso: decisao.proximoEhDescanso,
    ),
    RotinaMomento.agora => AlunoTodayAction(
      mode: AlunoTodayMode.workoutReady,
      route: '/checkin/executar',
      routeExtra: foco.treinoId,
      treinoNome: foco.treinoNome,
      exerciseCount: foco.totalExercicios,
      ordem: decisao.ordem,
      ordemTotal: decisao.ordemTotal,
      depoisNome: decisao.depoisNome,
      comeback: comeback,
      prazoFim: TreinoAtribuicaoPrazo.parseIsoDate(foco.dataFim),
    ),
    RotinaMomento.descansoDia => AlunoTodayAction(
      mode: AlunoTodayMode.descansoHoje,
      route: '/checkin/executar',
      routeExtra: foco.treinoId,
      treinoNome: foco.treinoNome,
      proximoTreinoId: foco.treinoId,
    ),
    RotinaMomento.preparacao => AlunoTodayAction(
      mode: AlunoTodayMode.awaitingRelease,
      route: '/checkin/treinos',
      treinoNome: foco.treinoNome,
    ),
  };
}

int? _feitosDaSessao(List<ExecucaoTreino> historico, int treinoId) {
  for (final item in historico) {
    if (item.treinoId == treinoId &&
        normalizeTreinoStatus(item.status) == treinoStatusEmAndamento) {
      return item.exerciciosConcluidos;
    }
  }
  return null;
}

bool _filled(String? value) => value != null && value.trim().isNotEmpty;
