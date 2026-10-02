import '../../checkin/utils/treino_ficha_status.dart';
import '../../coach/data/coach_proativo_repository.dart';
import '../../health/data/health_repository.dart';
import '../../monetizacao/data/upsell_repository.dart';
import '../../planos/data/planos_repository.dart';
import '../data/aluno_home_insight.dart';
import '../data/dashboard_repository.dart';
import 'aluno_home_week.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

const alunoHomeRoute = '/dashboard/aluno';
const alunoFinanceiroRoute = '/financeiro/aluno';
const alunoFeedbackVideoRoute = '/aluno/feedback-videos';

/// Atalhos da Home em ordem de prioridade. Sem rotas do dock (Hoje, Treinos,
/// Saúde, Chat, Perfil): o dock já leva a elas.
const alunoAtalhosPrioridade = [
  '/agenda/aluno',
  '/checkin/historico',
  '/aluno/habitos',
  '/aluno/desafios',
  alunoFinanceiroRoute,
  '/aluno/anamnese',
];
const alunoAtalhosMax = 3;

/// Ferramentas que dependem de um recurso do plano do personal (BFF
/// `recursosIndisponiveis`). Sem o recurso, a tela só mostraria o bloqueio.
const alunoFerramentaRecurso = {
  '/agenda/aluno': 'AGENDA',
  '/aluno/habitos': 'HABIT_COACHING',
  '/aluno/desafios': 'COMUNIDADE_GRUPOS',
  alunoFeedbackVideoRoute: 'FEEDBACK_VIDEO',
  alunoFinanceiroRoute: 'FINANCEIRO',
  '/aluno/recorrencia': 'FINANCEIRO',
};

/// Mesmas ferramentas pela matriz de `recursos` do plano do personal.
const alunoFerramentaPlanoRecurso = {
  '/aluno/habitos': PlanoRecursoKeys.habitos,
  '/aluno/desafios': PlanoRecursoKeys.desafios,
  alunoFeedbackVideoRoute: PlanoRecursoKeys.feedbackVideo,
  alunoFinanceiroRoute: PlanoRecursoKeys.financeiro,
  '/aluno/recorrencia': PlanoRecursoKeys.recorrencia,
};

/// [plano] nulo (ainda carregando) não esconde nada além do BFF.
bool alunoFerramentaLiberada(
  String rota,
  Set<String> indisponiveis, {
  PlanoFeatures? plano,
}) {
  if (indisponiveis.contains(alunoFerramentaRecurso[rota])) return false;
  final recurso = alunoFerramentaPlanoRecurso[rota];
  if (recurso == null) return true;
  if (indisponiveis.contains(recurso)) return false;
  return plano == null || plano.recurso(recurso).liberado;
}

/// Ofertas de pacote só com a loja liberada no plano do personal.
bool alunoOfertasLiberadas(PlanoFeatures? plano) =>
    plano == null || plano.recurso(PlanoRecursoKeys.loja).liberado;

/// Tudo que a Home do aluno deriva do BFF, calculado uma vez por bundle.
class AlunoHomeView {
  final AlunoTodayAction action;

  /// [alunoInsightNoFoco]: sem queda de ritmo no card de quem acabou de treinar.
  final AlunoHomeInsight? insight;

  /// Vazia com mensalidade atrasada: não oferecer compra a quem está devendo.
  final List<AlunoOferta> ofertas;

  /// Pendências em aberto, sem corte (base do COMPLETED de autonomia).
  final List<AlunoPendencia> pendenciasAbertas;

  /// As que aparecem na Home ([alunoPendenciasVisiveis]).
  final List<AlunoPendencia> pendencias;

  /// Coach sem o que outro bloco já diz ([alunoCoachVisiveis]).
  final List<CoachMensagem> coach;
  final AlunoHomeAviso aviso;

  /// Mensalidade atrasada, mesmo quando o atestado ocupa o aviso.
  final bool financeiroEmAtraso;
  final AlunoWeekSummary semana;

  /// Já concluiu algum treino. Antes disso semana e evolução só teriam zeros:
  /// o card de foco é o estado guiado da tela.
  final bool jaTreinou;
  final bool prontidaoVisivel;

  /// Treino pronto com a prontidão abaixo de [alunoProntidaoBaixaAbaixoDe]:
  /// o card de foco pede para ir mais leve.
  final bool prontidaoBaixa;

  /// A linha "Seu personal" do cabeçalho abre o chat.
  final bool chatNoCabecalho;
  final Set<String> recursosIndisponiveis;

  /// Plano do personal: esconde ferramentas cujo recurso não está liberado.
  final PlanoFeatures? planoPersonal;

  /// Próximo horário de hoje ou amanhã ([alunoHorarioNoFoco]).
  final DateTime? horarioNoFoco;

  const AlunoHomeView({
    required this.action,
    required this.insight,
    required this.pendenciasAbertas,
    required this.pendencias,
    required this.coach,
    required this.aviso,
    required this.semana,
    required this.jaTreinou,
    required this.prontidaoVisivel,
    required this.chatNoCabecalho,
    this.financeiroEmAtraso = false,
    this.prontidaoBaixa = false,
    this.ofertas = const [],
    this.recursosIndisponiveis = const {},
    this.planoPersonal,
    this.horarioNoFoco,
  });

  bool get semanaVisivel => jaTreinou && !semana.isEmpty;

  /// Destinos que já têm entrada acima dos atalhos.
  Set<String> get rotasNoTopo => {
    action.route,
    if (aviso == AlunoHomeAviso.financeiro) alunoFinanceiroRoute,
    if (aviso == AlunoHomeAviso.atestado || aviso == AlunoHomeAviso.anamnese)
      '/aluno/anamnese',
    if (chatNoCabecalho) '/chat/aluno',
    for (final p in pendencias) Uri.parse(p.tipo.route).path,
  };

  bool ferramentaLiberada(String rota) =>
      alunoFerramentaLiberada(rota, recursosIndisponiveis, plano: planoPersonal);

  List<String> get atalhos => alunoAtalhosPrioridade
      .where((r) => !rotasNoTopo.contains(r) && ferramentaLiberada(r))
      .take(alunoAtalhosMax)
      .toList(growable: false);
}

AlunoHomeView buildAlunoHomeView(
  AlunoDashboardHomeBundle home, {
  required bool agendaReviewed,
  DateTime? now,
}) {
  final agora = now ?? DateTime.now();
  final action = resolveAlunoTodayAction(
    aluno: home.aluno,
    treinos: home.treinos,
    historico: home.historico,
    now: agora,
  );
  final inadimplente = home.aluno.inadimplente;
  final plano = home.planoFeatures?.normalizeForTier();
  final abertas = listAlunoPendenciasAbertas(
    aluno: home.aluno,
    medidas: home.medidas,
    naoLidasDoPersonal: home.chat.naoLidasDoPersonal,
    agendaProximoInicio: home.agendaProximoInicio,
    agendaReviewed: agendaReviewed,
    todayMode: action.mode,
    now: agora,
  );
  final prontidaoVisivel = alunoProntidaoVisivel(
    snapshot: home.recovery,
    stale: home.recoveryStale,
    hasWearableHistory: home.hasWearableHistory,
  );
  final coach = alunoCoachVisiveis(
    home.coachMensagens,
    comeback: action.comeback,
    prontidaoVisivel: prontidaoVisivel,
  );
  return AlunoHomeView(
    action: action,
    insight: alunoInsightNoFoco(home.insight, action.mode),
    ofertas:
        inadimplente ||
                home.recursosIndisponiveis.contains('LOJA_DIGITAL') ||
                !alunoOfertasLiberadas(plano)
            ? const []
            : home.upsellPendentes,
    pendenciasAbertas: abertas,
    pendencias: alunoPendenciasVisiveis(abertas, action.mode),
    coach: coach,
    aviso: resolveAlunoHomeAviso(
      inadimplente: inadimplente,
      anamnese: home.anamnesePendente,
      coachMensagens: coach.length,
    ),
    financeiroEmAtraso: inadimplente,
    semana: buildAlunoWeekSummary(
      concluidosSemanaIso: home.concluidosSemanaIso,
      frequenciaDias: home.frequenciaDias,
      streakAtual: home.streakAtual,
      volumeSemanaKg: home.volumeSemanaKg,
    ),
    jaTreinou: home.historico.any(
      (h) => normalizeTreinoStatus(h.status) == treinoStatusConcluido,
    ),
    prontidaoVisivel: prontidaoVisivel,
    prontidaoBaixa: alunoProntidaoBaixa(
      mode: action.mode,
      snapshot: home.recovery,
      prontidaoVisivel: prontidaoVisivel,
    ),
    chatNoCabecalho: home.personalBrand.nomePersonal.trim().isNotEmpty,
    recursosIndisponiveis: home.recursosIndisponiveis,
    planoPersonal: plano,
    horarioNoFoco: alunoHorarioNoFoco(home.agendaProximoInicio, agora),
  );
}

/// Hoje (ainda por vir) ou amanhã: vai para o card de foco em vez de virar
/// pendência.
DateTime? alunoHorarioNoFoco(DateTime? inicio, DateTime now) {
  if (inicio == null || !inicio.isAfter(now)) return null;
  return alunoDiasAte(inicio, now) < alunoAgendaPendenciaDesdeDias
      ? inicio
      : null;
}

/// A view muda sozinha quando o horário do foco passa ou o dia vira.
DateTime alunoHomeViewValidaAte(AlunoHomeView view, DateTime now) {
  final meiaNoite = DateTime(now.year, now.month, now.day + 1);
  final horario = view.horarioNoFoco;
  return horario != null && horario.isBefore(meiaNoite) ? horario : meiaNoite;
}

AlunoHomeInsight? alunoInsightNoFoco(
  AlunoHomeInsight? insight,
  AlunoTodayMode mode,
) =>
    mode == AlunoTodayMode.workoutDone &&
            insight?.tipo == AlunoInsightTipo.ritmoCaiu
        ? null
        : insight;

/// Abaixo daqui o `RecoveryScoreCalculator` do backend rotula "Descanso
/// recomendado".
const alunoProntidaoBaixaAbaixoDe = 45;

/// Nota ausente é indisponível, não baixa: sem conselho de ir mais leve.
bool alunoProntidaoBaixa({
  required AlunoTodayMode mode,
  required RecoverySnapshot? snapshot,
  required bool prontidaoVisivel,
}) {
  final score = snapshot?.recoveryScore;
  return mode == AlunoTodayMode.workoutReady &&
      prontidaoVisivel &&
      score != null &&
      score < alunoProntidaoBaixaAbaixoDe;
}

/// Prontidão de hoje com histórico de wearable, ou o convite para sincronizar
/// quando a última é antiga. Sem wearable, o bloco não existe.
bool alunoProntidaoVisivel({
  required RecoverySnapshot? snapshot,
  required bool stale,
  required bool hasWearableHistory,
}) => snapshot == null ? stale : hasWearableHistory;

/// Coach sem repetir a Home: dias sem treino e sequência parada já são a
/// retomada do card "Hoje"; sono curto já está no card de prontidão.
List<CoachMensagem> alunoCoachVisiveis(
  List<CoachMensagem> mensagens, {
  required bool comeback,
  required bool prontidaoVisivel,
}) => [
  for (final m in mensagens)
    if (!(comeback &&
            (m.tipo == 'SEM_TREINO_5D' || m.tipo == 'STREAK_QUEBRADO')) &&
        !(prontidaoVisivel && m.tipo == 'SONO_BAIXO'))
      m,
];
