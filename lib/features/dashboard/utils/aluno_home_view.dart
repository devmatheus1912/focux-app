import '../../health/data/health_repository.dart';
import '../data/aluno_home_insight.dart';
import '../data/dashboard_repository.dart';
import 'aluno_home_week.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

/// Atalhos da Home em ordem de prioridade. Sem rotas do dock (Hoje, Treinos,
/// Saúde, Chat, Perfil): o dock já leva a elas.
const alunoAtalhosPrioridade = [
  '/agenda/aluno',
  '/aluno/anamnese',
  '/checkin/historico',
  '/aluno/habitos',
  '/aluno/desafios',
  '/financeiro/aluno',
];
const alunoAtalhosMax = 3;

/// Tudo que a Home do aluno deriva do BFF, calculado uma vez por bundle.
class AlunoHomeView {
  final AlunoTodayAction action;

  /// Null no bloqueio financeiro: conquista não divide o card com cobrança.
  final AlunoHomeInsight? insight;

  /// Pendências em aberto, sem corte (base do COMPLETED de autonomia).
  final List<AlunoPendencia> pendenciasAbertas;

  /// As que aparecem na Home ([alunoPendenciasVisiveis]).
  final List<AlunoPendencia> pendencias;
  final AlunoHomeAviso aviso;
  final AlunoWeekSummary semana;

  /// Sem treino nem histórico: o card de foco é o estado guiado da tela.
  final bool semTreino;
  final bool prontidaoVisivel;

  /// A linha "Seu personal" do cabeçalho abre o chat.
  final bool chatNoCabecalho;

  const AlunoHomeView({
    required this.action,
    required this.insight,
    required this.pendenciasAbertas,
    required this.pendencias,
    required this.aviso,
    required this.semana,
    required this.semTreino,
    required this.prontidaoVisivel,
    required this.chatNoCabecalho,
  });

  bool get semanaVisivel => !semTreino && !semana.isEmpty;

  /// Destinos que já têm entrada acima dos atalhos.
  Set<String> get rotasNoTopo => {
    action.route,
    if (insight?.acao?.rota case final rota?) rota,
    if (aviso == AlunoHomeAviso.anamnese) '/aluno/anamnese',
    if (chatNoCabecalho) '/chat/aluno',
    for (final p in pendencias) Uri.parse(p.tipo.route).path,
  };

  List<String> get atalhos => alunoAtalhosPrioridade
      .where((r) => !rotasNoTopo.contains(r))
      .take(alunoAtalhosMax)
      .toList(growable: false);
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
  final abertas = listAlunoPendenciasAbertas(
    aluno: home.aluno,
    medidas: home.medidas,
    naoLidasDoPersonal: home.chat.naoLidasDoPersonal,
    agendaReviewed: agendaReviewed,
    todayMode: action.mode,
    now: now,
  );
  return AlunoHomeView(
    action: action,
    insight: action.mode == AlunoTodayMode.financialHold ? null : home.insight,
    pendenciasAbertas: abertas,
    pendencias: alunoPendenciasVisiveis(abertas, action.mode),
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
    prontidaoVisivel: alunoProntidaoVisivel(
      snapshot: home.recovery,
      stale: home.recoveryStale,
      hasWearableHistory: home.hasWearableHistory,
    ),
    chatNoCabecalho: home.personalBrand.nomePersonal.trim().isNotEmpty,
  );
}

/// Prontidão de hoje com histórico de wearable, ou o convite para sincronizar
/// quando a última é antiga. Sem wearable, o bloco não existe.
bool alunoProntidaoVisivel({
  required RecoverySnapshot? snapshot,
  required bool stale,
  required bool hasWearableHistory,
}) => snapshot == null ? stale : hasWearableHistory;
