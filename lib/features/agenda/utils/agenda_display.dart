import '../data/agenda_repository.dart';
import 'agenda_schedule.dart';
import 'agenda_status.dart';

const agendaComoCalculamos =
    'O dia usa os horários do personal neste fuso. Lacunas são faixas livres entre atendimentos.';

enum AgendaAlunoChip { todos, confirmar, confirmados }

String agendaAlunoChipLabel(AgendaAlunoChip chip) => switch (chip) {
  AgendaAlunoChip.todos => 'Todos',
  AgendaAlunoChip.confirmar => 'A confirmar',
  AgendaAlunoChip.confirmados => 'Confirmados',
};

String? agendaAlunoChipStatus(AgendaAlunoChip chip) => switch (chip) {
  AgendaAlunoChip.todos => null,
  AgendaAlunoChip.confirmar => 'AGENDADO',
  AgendaAlunoChip.confirmados => 'CONFIRMADO',
};

String agendaAlunoCountLabel(int count) {
  if (count <= 0) return 'Nenhum compromisso';
  if (count == 1) return '1 compromisso';
  return '$count compromissos';
}

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

bool agendaAlunoJaPassou(Agendamento ag, {DateTime? now}) =>
    ag.fim.isBefore(now ?? DateTime.now());

/// Só sessão futura ainda em AGENDADO; o backend recusa o resto.
bool agendaAlunoPodeConfirmar(Agendamento ag, {DateTime? now}) =>
    ag.status == 'AGENDADO' && ag.inicio.isAfter(now ?? DateTime.now());

/// Sessão passada fala do atendimento; futura, do status do horário.
String agendaAlunoStatusLabel(Agendamento ag, {DateTime? now}) {
  if (!agendaAlunoJaPassou(ag, now: now)) return agendaStatusLabel(ag.status);
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
      return agendaStatusLabel(ag.status);
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
