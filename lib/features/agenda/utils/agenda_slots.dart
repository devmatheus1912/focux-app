import '../../../core/api/api_error.dart';
import '../data/agenda_repository.dart';
import 'agenda_day_lane.dart';
import 'agenda_schedule.dart';

const agendaDuracoesMin = [30, 45, 60, 90];

const agendaDuracaoPadraoMin = 60;

const agendaSlotPrimeiraHora = 6;

const agendaSlotUltimaHora = 22;

const agendaHorarioPassadoCodigo = 'AGENDA_HORARIO_PASSADO';

const agendaConflitoCodigo = 'AGENDA_CONFLITO';

const agendaHorarioPassadoMensagem = 'Escolha um horário a partir de agora.';

/// Grade de 30 em 30 min, 06:00–22:30.
List<DateTime> agendaSlotsDoDia(DateTime day) => [
  for (var hour = agendaSlotPrimeiraHora; hour <= agendaSlotUltimaHora; hour++)
    for (final minute in const [0, 30])
      DateTime(day.year, day.month, day.day, hour, minute),
];

DateTime agendaDayStart(DateTime d) => DateTime(d.year, d.month, d.day);

bool agendaDayIsPast(DateTime day, {DateTime? now}) =>
    agendaDayStart(day).isBefore(agendaDayStart(now ?? DateTime.now()));

/// O atendimento não vira o dia: termina no máximo às 23:59.
bool agendaSlotFitsDay(DateTime inicio, int duracaoMin) {
  final limite = DateTime(inicio.year, inicio.month, inicio.day, 23, 59);
  return !inicio.add(Duration(minutes: duracaoMin)).isAfter(limite);
}

/// Primeiro atendimento ativo que cruza [inicio, inicio + duração). Encostar
/// no fim de outro horário não conflita.
Agendamento? agendaSlotConflict(
  DateTime inicio,
  int duracaoMin,
  Iterable<Agendamento> events, {
  int? excludeId,
}) {
  final fim = inicio.add(Duration(minutes: duracaoMin));
  for (final ag in events) {
    if (ag.status == 'CANCELADO' || ag.id == excludeId) continue;
    if (ag.inicio.isBefore(fim) && inicio.isBefore(ag.fim)) return ag;
  }
  return null;
}

String agendaPrimeiroNome(String nome) {
  final parts = nome.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.first;
}

String agendaConflitoMensagem(Agendamento ag) =>
    'Horário ocupado: ${agendaPrimeiroNome(ag.alunoNome)} ${agendaHm(ag.inicio)}–${agendaHm(ag.fim)}.';

String agendaDuracaoLabel(int minutos) {
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

/// Chips da sheet; uma duração fora da lista (remarcação) entra como extra.
List<int> agendaDuracoesCom(int duracaoMin) =>
    agendaDuracoesMin.contains(duracaoMin) || duracaoMin <= 0
        ? agendaDuracoesMin
        : ([...agendaDuracoesMin, duracaoMin]..sort());

/// Maior chip que cabe em [minutos]; nulo se nem 30 min cabem.
int? agendaDuracaoQueCabe(int minutos) {
  int? best;
  for (final d in agendaDuracoesMin) {
    if (d <= minutos) best = d;
  }
  return best;
}

/// Próximo início de grade (:00/:30) a partir de [now].
DateTime agendaProximoSlot(DateTime now) {
  final base = DateTime(now.year, now.month, now.day, now.hour);
  if (now.minute == 0 && now.second == 0 && now.millisecond == 0) return base;
  if (now.minute < 30 ||
      (now.minute == 30 && now.second == 0 && now.millisecond == 0)) {
    return base.add(const Duration(minutes: 30));
  }
  return base.add(const Duration(hours: 1));
}

class AgendaSlotSeed {
  const AgendaSlotSeed({required this.inicio, required this.duracaoMin});

  final DateTime inicio;
  final int duracaoMin;
}

/// Encaixe de uma lacuna: só a parte futura, no primeiro slot da grade, até
/// 60 min. Nulo quando a lacuna já passou ou ficou curta demais.
AgendaSlotSeed? agendaGapSeed(AgendaLaneGap gap, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final inicio = agendaProximoSlot(gap.from.isBefore(n) ? n : gap.from);
  final livre = gap.to.difference(inicio).inMinutes;
  final cabe = agendaDuracaoQueCabe(
    livre < agendaDuracaoPadraoMin ? livre : agendaDuracaoPadraoMin,
  );
  if (cabe == null) return null;
  return AgendaSlotSeed(inicio: inicio, duracaoMin: cabe);
}

bool agendaIsSlotError(Object error) {
  final codigo = ApiError.from(error)?.codigo;
  return codigo == agendaConflitoCodigo || codigo == agendaHorarioPassadoCodigo;
}

/// Texto do 400/409 de horário; nulo para qualquer outro erro.
String? agendaSlotErrorMessage(Object error) {
  if (!agendaIsSlotError(error)) return null;
  final api = ApiError.from(error);
  return api?.mensagem ??
      (api?.codigo == agendaHorarioPassadoCodigo
          ? agendaHorarioPassadoMensagem
          : 'Horário ocupado. Escolha outro.');
}

/// Valida antes de chamar a API; devolve o aviso ou nulo se o horário serve.
String? agendaSlotLocalError(
  DateTime inicio,
  int duracaoMin,
  Iterable<Agendamento> events, {
  int? excludeId,
  DateTime? now,
}) {
  if (agendaDateTimeIsInPast(inicio, now: now)) {
    return agendaHorarioPassadoMensagem;
  }
  final conflito = agendaSlotConflict(
    inicio,
    duracaoMin,
    events,
    excludeId: excludeId,
  );
  return conflito == null ? null : agendaConflitoMensagem(conflito);
}
