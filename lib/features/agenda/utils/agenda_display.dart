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

String agendaAlunoWhenLabel(DateTime inicio, DateTime fim) {
  final day = inicio.day.toString().padLeft(2, '0');
  final month = inicio.month.toString().padLeft(2, '0');
  final start =
      '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
  final end =
      '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';
  return '$day/$month $start – $end';
}

String agendaAlunoDefaultTitle(String? titulo) {
  final value = titulo?.trim();
  if (value == null || value.isEmpty) return 'Sessão de treino';
  return value;
}
