import '../../checkin/utils/treino_ficha_status.dart';
import '../../coach/data/coach_proativo_repository.dart';
import '../../health/data/health_repository.dart';
import '../../monetizacao/data/upsell_repository.dart';
import '../data/aluno_home_insight.dart';
import '../data/dashboard_repository.dart';
import 'aluno_home_week.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

const alunoHomeRoute = '/dashboard/aluno';
const alunoFinanceiroRoute = '/financeiro/aluno';

/// Atalhos da Home em ordem de prioridade. Sem rotas do dock (Hoje, Treinos,
/// Saúde, Chat, Perfil): o dock já leva a elas.
const alunoAtalhosPrioridade = [
  '/agenda/aluno',
  '/aluno/anamnese',
  '/checkin/historico',
  '/aluno/habitos',
  '/aluno/desafios',
  alunoFinanceiroRoute,
];
const alunoAtalhosMax = 3;

/// Ferramentas que dependem de um recurso do plano do personal (BFF
/// `recursosIndisponiveis`). Sem o recurso, a tela só mostraria o bloqueio.
const alunoFerramentaRecurso = {
  '/agenda/aluno': 'AGENDA',
  '/aluno/habitos': 'HABIT_COACHING',
  '/aluno/desafios': 'COMUNIDADE_GRUPOS',
};

bool alunoFerramentaLiberada(String rota, Set<String> indisponiveis) =>
    !indisponiveis.contains(alunoFerramentaRecurso[rota]);

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

  /// O último recorde é dos últimos [alunoRecordeNovoDias] dias.
  final bool recordeRecente;

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
    this.recordeRecente = false,
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

  List<String> get atalhos => alunoAtalhosPrioridade
      .where(
        (r) =>
            !rotasNoTopo.contains(r) &&
            alunoFerramentaLiberada(r, recursosIndisponiveis),
      )
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
    ofertas: inadimplente ? const [] : home.upsellPendentes,
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
    recordeRecente: alunoRecordeRecente(
      home.recordes.isEmpty ? null : home.recordes.first.data,
      agora,
    ),
    horarioNoFoco: alunoHorarioNoFoco(home.agendaProximoInicio, agora),
  );
}

/// Hoje ou amanhã: vai para o card de foco em vez de virar pendência.
DateTime? alunoHorarioNoFoco(DateTime? inicio, DateTime now) {
  if (inicio == null) return null;
  final dias = alunoDiasAte(inicio, now);
  return dias >= 0 && dias < alunoAgendaPendenciaDesdeDias ? inicio : null;
}

AlunoHomeInsight? alunoInsightNoFoco(
  AlunoHomeInsight? insight,
  AlunoTodayMode mode,
) =>
    mode == AlunoTodayMode.workoutDone &&
            insight?.tipo == AlunoInsightTipo.ritmoCaiu
        ? null
        : insight;

/// Mesmo corte de "Recuperação parcial" do `RecoveryScoreCalculator` do backend.
const alunoProntidaoBaixaAbaixoDe = 45;

bool alunoProntidaoBaixa({
  required AlunoTodayMode mode,
  required RecoverySnapshot? snapshot,
  required bool prontidaoVisivel,
}) =>
    mode == AlunoTodayMode.workoutReady &&
    prontidaoVisivel &&
    snapshot != null &&
    snapshot.recoveryScore < alunoProntidaoBaixaAbaixoDe;

const alunoRecordeNovoDias = 7;

bool alunoRecordeRecente(String? data, DateTime now) {
  final dia = data == null ? null : DateTime.tryParse(data);
  if (dia == null) return false;
  final hoje = DateTime(now.year, now.month, now.day);
  final dias = hoje.difference(DateTime(dia.year, dia.month, dia.day)).inDays;
  return dias >= 0 && dias <= alunoRecordeNovoDias;
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
