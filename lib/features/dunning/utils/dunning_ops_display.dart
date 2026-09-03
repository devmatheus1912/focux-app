import '../../../core/utils/pt_br_display.dart';

String dunningContextoLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'ALUNO_MENSALIDADE':
      return 'Mensalidade';
    case 'FOCUX_SUBSCRIPTION':
      return 'Assinatura Focux';
    default:
      return raw.trim().isEmpty ? 'Pagamento' : raw.trim();
  }
}

String dunningTentativaLabel(int tentativa) {
  if (tentativa <= 0) return 'Ainda sem retentativa';
  if (tentativa == 1) return 'Tentativa 1';
  return 'Tentativa $tentativa';
}

String dunningFalhaTitulo(String? alunoNome, String contexto) {
  final nome = alunoNome?.trim();
  if (nome != null && nome.isNotEmpty) return nome;
  return dunningContextoLabel(contexto);
}

String dunningFalhaSubtitle({
  required String contexto,
  String? alunoNome,
  String? motivo,
  required int tentativa,
}) {
  final nome = alunoNome?.trim();
  final mostraContexto = nome != null && nome.isNotEmpty;
  final parts = <String>[
    if (mostraContexto) dunningContextoLabel(contexto),
    if (motivo != null && motivo.trim().isNotEmpty) displayPtBr(motivo.trim()),
    dunningTentativaLabel(tentativa),
  ];
  return parts.join(' · ');
}

String dunningMoneyLabel(num? value) {
  if (value == null) return '—';
  return formatBrlCurrency(value);
}

String dunningRateLabel(double rate) => '${rate.toStringAsFixed(1)}%';

String dunningRecuperadasLabel(int recuperadas, int total) =>
    '$recuperadas de $total';

bool dunningTaxaFraca(double rate, int total) => total > 0 && rate < 50;

List<T> dunningFalhasPreview<T>(List<T> items) =>
    items.take(3).toList(growable: false);

const dunningComoCalculamos =
    'Recuperadas dividido pelo total de falhas no recorte. É a mesma taxa da Receita recorrente.';
