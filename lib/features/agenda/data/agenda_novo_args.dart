import 'agenda_repository.dart';

/// Extra de `/agenda/novo`. [agendamentos] é o mês já carregado pela agenda,
/// para a grade marcar os horários ocupados sem nova chamada.
class AgendaNovoArgs {
  const AgendaNovoArgs({
    required this.day,
    this.inicio,
    this.duracaoMin,
    this.agendamentos,
  });

  final DateTime day;
  final DateTime? inicio;
  final int? duracaoMin;
  final List<Agendamento>? agendamentos;

  /// Compatível com o extra antigo: `DateTime` com hora vira início sugerido.
  factory AgendaNovoArgs.fromSeed(DateTime? seed) {
    final day = seed ?? DateTime.now();
    final temHora = seed != null && (seed.hour != 0 || seed.minute != 0);
    return AgendaNovoArgs(day: day, inicio: temHora ? seed : null);
  }
}
