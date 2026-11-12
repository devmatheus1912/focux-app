import '../data/agenda_repository.dart';
import 'agenda_schedule.dart';
import 'agenda_status.dart';

const agendaComoCalculamos =
    'O dia usa os horários do personal neste fuso. Lacunas são faixas livres entre atendimentos.';

const agendaAlunoEscopoProximas = 'proximas';
const agendaAlunoEscopoAnteriores = 'anteriores';

/// "Hoje · 08:30–09:30", "Amanhã · …" ou "Sex, 20 nov · 08:30–09:30".
String agendaAlunoDiaLabel(DateTime inicio, DateTime fim, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final hoje = DateTime(n.year, n.month, n.day);
  final dia = DateTime(inicio.year, inicio.month, inicio.day);
  final diff = dia.difference(hoje).inDays;
  final quando =
      diff == 0
          ? 'Hoje'
          : diff == 1
          ? 'Amanhã'
          : '${agendaWeekdayShort(inicio.weekday)}, ${inicio.day} ${agendaMonthShort[inicio.month]}';
  final hora =
      fim.isAfter(inicio)
          ? '${agendaHm(inicio)}–${agendaHm(fim)}'
          : agendaHm(inicio);
  return '$quando · $hora';
}

/// O cartão "Próxima sessão" só com a que ainda vale (agendada ou
/// confirmada): cancelada não pode virar "Confirmada" (bug de 12/11).
Agendamento? agendaAlunoProximaAtiva(List<Agendamento> proximas) =>
    proximas.where((a) => agendaStatusIsActionable(a.status)).firstOrNull;

/// "Hoje", "Amanhã" ou "Sex, 27 nov" (o horário vai embaixo).
String agendaAlunoSoDia(DateTime inicio, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final hoje = DateTime(n.year, n.month, n.day);
  final dia = DateTime(inicio.year, inicio.month, inicio.day);
  final diff = dia.difference(hoje).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  return '${agendaWeekdayShort(inicio.weekday)}, ${inicio.day} ${agendaMonthShort[inicio.month]}';
}

String agendaAlunoHorario(Agendamento ag) =>
    ag.fim.isAfter(ag.inicio)
        ? '${agendaHm(ag.inicio)}–${agendaHm(ag.fim)}'
        : agendaHm(ag.inicio);

/// Para o aluno, "sessão" é feminino em tudo.
String agendaAlunoStatusSessao(String status) => switch (status) {
  'AGENDADO' => 'Agendada',
  'CONFIRMADO' => 'Confirmada',
  'CONCLUIDO' => 'Concluída',
  'CANCELADO' => 'Cancelada',
  'PRESENTE' => 'Presente',
  'FALTA' => 'Falta',
  _ => agendaStatusLabel(status),
};

/// Sessão nos próximos 7 dias; depois disso não vale ocupar a aba Treinos.
DateTime? agendaProximaDaSemana(DateTime? inicio, DateTime agora) {
  if (inicio == null || inicio.isBefore(agora)) return null;
  return inicio.difference(agora).inDays < 7 ? inicio : null;
}

bool agendaAlunoJaPassou(Agendamento ag, {DateTime? now}) =>
    ag.fim.isBefore(now ?? DateTime.now());

/// Só sessão futura ainda em AGENDADO; o backend recusa o resto.
bool agendaAlunoPodeConfirmar(Agendamento ag, {DateTime? now}) =>
    ag.status == 'AGENDADO' && ag.inicio.isAfter(now ?? DateTime.now());

/// Sessão passada fala do atendimento; futura, do status do horário.
String agendaAlunoStatusLabel(Agendamento ag, {DateTime? now}) {
  if (!agendaAlunoJaPassou(ag, now: now)) {
    return agendaAlunoStatusSessao(ag.status);
  }
  final atendimento = ag.statusAtendimento?.trim().toUpperCase();
  switch (atendimento ?? ag.status) {
    case 'PRESENTE':
    case 'COMPARECEU':
    case 'CONCLUIDO':
      return 'Compareceu';
    case 'FALTA':
    case 'FALTOU':
      return 'Faltou';
    default:
      return agendaAlunoStatusSessao(ag.status);
  }
}

/// Próximas em ordem crescente; anteriores da mais recente para trás.
List<Agendamento> agendaAlunoProximas(
  Iterable<Agendamento> items, {
  DateTime? now,
}) =>
    items.where((a) => !agendaAlunoJaPassou(a, now: now)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

List<Agendamento> agendaAlunoAnteriores(
  Iterable<Agendamento> items, {
  DateTime? now,
}) =>
    items.where((a) => agendaAlunoJaPassou(a, now: now)).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));

String agendaAlunoDefaultTitle(String? titulo) {
  final value = titulo?.trim();
  if (value == null || value.isEmpty) return 'Sessão de treino';
  return value;
}
