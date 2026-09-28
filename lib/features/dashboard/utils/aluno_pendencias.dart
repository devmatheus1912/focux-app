import '../../alunos/data/aluno_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../data/aluno_home_anamnese.dart';
import 'aluno_today_action.dart';

/// Pendências do aluno, em ordem de prioridade. `taskId` e `taskTitlePt`
/// seguem o contrato de `POST /api/aluno/autonomia/eventos` (vira ação do personal).
/// Foto e medida abrem o editor já na ação (`PerfilEditarAcao`).
enum AlunoPendenciaTipo {
  perfil('perfil-base', 'Completar perfil base', '/aluno/perfil/editar'),
  foto('foto-dados', 'Adicionar foto', '/aluno/perfil/editar?acao=foto'),
  medida(
    'medida-recente',
    'Atualizar medida quinzenal',
    '/aluno/perfil/editar?acao=medida',
  ),
  chat('chat-contexto', 'Responder o personal', '/chat/aluno'),
  agenda('agenda-semana', 'Conferir próximo horário', '/agenda/aluno');

  const AlunoPendenciaTipo(this.taskId, this.taskTitlePt, this.route);

  final String taskId;
  final String taskTitlePt;
  final String route;
}

class AlunoPendencia {
  final AlunoPendenciaTipo tipo;

  /// Medida: aluno nunca registrou (texto de primeira medida).
  final bool primeiraVez;

  /// Agenda: início do próximo horário.
  final DateTime? quando;

  /// Chat: mensagens do personal não lidas.
  final int quantidade;

  const AlunoPendencia(
    this.tipo, {
    this.primeiraVez = false,
    this.quando,
    this.quantidade = 0,
  });
}

const alunoPendenciasMax = 3;
const alunoMedidaValidadeDias = 14;

/// Horário de hoje e amanhã fica na linha do card de foco.
const alunoAgendaPendenciaDesdeDias = 2;

/// Dias de calendário entre hoje e [alvo] (negativo = passado), sem horário de verão.
int alunoDiasAte(DateTime alvo, DateTime agora) =>
    DateTime.utc(
      alvo.year,
      alvo.month,
      alvo.day,
    ).difference(DateTime.utc(agora.year, agora.month, agora.day)).inDays;

/// Todas as pendências em aberto, em ordem de urgência. A Home mostra as
/// [alunoPendenciasMax] primeiras; uma fora do top 3 continua aberta.
/// Perfil e foto nunca aparecem juntos. Agenda só depois de amanhã
/// (`agendaProximoInicio` do BFF) e ainda não vista ([agendaReviewed]).
List<AlunoPendencia> listAlunoPendenciasAbertas({
  required Aluno aluno,
  required List<MedidaCorporal> medidas,
  required int naoLidasDoPersonal,
  required DateTime? agendaProximoInicio,
  required bool agendaReviewed,
  required AlunoTodayMode todayMode,
  DateTime? now,
}) {
  final agora = now ?? DateTime.now();
  final hoje = _dateOnly(agora);
  final ultimaMedida = _ultimaMedida(medidas);
  final medidaVencida =
      ultimaMedida == null ||
      hoje.difference(ultimaMedida).inDays > alunoMedidaValidadeDias;
  final inicio = agendaProximoInicio;
  final agendaPendente =
      inicio != null &&
      !agendaReviewed &&
      alunoDiasAte(inicio, agora) >= alunoAgendaPendenciaDesdeDias;
  final cadastroNoFoco = todayMode == AlunoTodayMode.profileSetup;

  return [
    if (naoLidasDoPersonal > 0)
      AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: naoLidasDoPersonal),
    if (agendaPendente)
      AlunoPendencia(AlunoPendenciaTipo.agenda, quando: inicio),
    if (medidaVencida)
      AlunoPendencia(
        AlunoPendenciaTipo.medida,
        primeiraVez: ultimaMedida == null,
      ),
    if (!cadastroNoFoco && alunoProfileCompletion(aluno) < 100)
      const AlunoPendencia(AlunoPendenciaTipo.perfil)
    else if (!cadastroNoFoco && !_filled(aluno.fotoUrl))
      const AlunoPendencia(AlunoPendenciaTipo.foto),
  ];
}

/// As que aparecem na Home: sem repetir o destino do foco e cortadas em
/// [alunoPendenciasMax]. As escondidas seguem abertas para a autonomia.
List<AlunoPendencia> alunoPendenciasVisiveis(
  List<AlunoPendencia> abertas,
  AlunoTodayMode todayMode,
) => abertas
    .where(
      (p) =>
          !(todayMode == AlunoTodayMode.noWorkout &&
              p.tipo == AlunoPendenciaTipo.chat),
    )
    .take(alunoPendenciasMax)
    .toList(growable: false);

/// Um aviso por vez abaixo do card de foco. Saúde antes de dinheiro.
enum AlunoHomeAviso { atestado, financeiro, anamnese, coach, nenhum }

AlunoHomeAviso resolveAlunoHomeAviso({
  required bool inadimplente,
  required AlunoAnamnesePendente? anamnese,
  required int coachMensagens,
}) {
  if (anamnese == AlunoAnamnesePendente.precisaAtestado) {
    return AlunoHomeAviso.atestado;
  }
  if (inadimplente) return AlunoHomeAviso.financeiro;
  if (anamnese == AlunoAnamnesePendente.solicitada) {
    return AlunoHomeAviso.anamnese;
  }
  if (coachMensagens > 0) return AlunoHomeAviso.coach;
  return AlunoHomeAviso.nenhum;
}

DateTime? _ultimaMedida(List<MedidaCorporal> medidas) {
  DateTime? ultima;
  for (final m in medidas) {
    final data = DateTime.tryParse(m.data);
    if (data == null) continue;
    final d = _dateOnly(data);
    if (ultima == null || d.isAfter(ultima)) ultima = d;
  }
  return ultima;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _filled(String? value) => value != null && value.trim().isNotEmpty;
