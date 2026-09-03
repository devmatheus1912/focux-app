/// Tipos que o BE já agrega em `/api/analytics` (CADASTRO / CHECKIN).
/// Só mapeia ProductEvents existentes — sem nome novo.
String? productEventToFunnelTipo(String event) {
  return switch (event) {
    'aluno_created' => 'CADASTRO',
    _ => null,
  };
}

int? funnelAlunoIdFromProps(Map<String, Object?>? props) {
  final raw = props?['alunoId'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}
