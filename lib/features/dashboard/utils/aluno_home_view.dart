import '../data/dashboard_repository.dart';
import 'aluno_home_week.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

/// Tudo que a Home do aluno deriva do BFF, calculado uma vez por bundle.
class AlunoHomeView {
  final AlunoTodayAction action;

  /// Pendências em aberto, sem corte (base do COMPLETED de autonomia).
  final List<AlunoPendencia> pendenciasAbertas;
  final AlunoHomeAviso aviso;
  final AlunoWeekSummary semana;

  /// Sem treino nem histórico: o card de foco é o estado guiado da tela.
  final bool semTreino;

  const AlunoHomeView({
    required this.action,
    required this.pendenciasAbertas,
    required this.aviso,
    required this.semana,
    required this.semTreino,
  });

  /// As que cabem na Home.
  List<AlunoPendencia> get pendencias =>
      pendenciasAbertas.take(alunoPendenciasMax).toList(growable: false);
}

AlunoHomeView buildAlunoHomeView(
  AlunoDashboardHomeBundle home, {
  required bool agendaReviewed,
  DateTime? now,
}) {
  final action = resolveAlunoTodayAction(
    aluno: home.aluno,
    treinos: home.treinos,
    historico: home.historico,
  );
  return AlunoHomeView(
    action: action,
    pendenciasAbertas: listAlunoPendenciasAbertas(
      aluno: home.aluno,
      medidas: home.medidas,
      naoLidasDoPersonal: home.chat.naoLidasDoPersonal,
      agendaReviewed: agendaReviewed,
      todayMode: action.mode,
      now: now,
    ),
    aviso: resolveAlunoHomeAviso(
      anamnesePendente: home.anamnesePendente != null,
      coachMensagens: home.coachMensagens.length,
    ),
    semana: buildAlunoWeekSummary(
      concluidosSemanaIso: home.concluidosSemanaIso,
      frequenciaDias: home.frequenciaDias,
      streakAtual: home.streakAtual,
      volumeSemanaKg: home.volumeSemanaKg,
    ),
    semTreino: home.treinos.isEmpty && home.historico.isEmpty,
  );
}
