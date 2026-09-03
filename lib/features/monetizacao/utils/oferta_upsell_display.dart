import '../../../core/utils/pt_br_display.dart';

const ofertaGatilhoValues = ['MANUAL', 'CHECKIN', 'TRILHA_CONCLUIDA'];

String ofertaGatilhoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'MANUAL':
      return 'Manual';
    case 'CHECKIN':
      return 'Check-in';
    case 'TRILHA':
    case 'TRILHA_CONCLUIDA':
      return 'Trilha';
    case '':
      return 'Manual';
    default:
      return tipo!.trim();
  }
}

String ofertaSubtitle({required String tipoGatilho, String? descricao}) {
  final gatilho = ofertaGatilhoLabel(tipoGatilho);
  final desc = descricao?.trim();
  if (desc == null || desc.isEmpty) return gatilho;
  return '$gatilho · $desc';
}

String ofertaValorLabel(num valor) => formatBrlCurrency(valor);

String ofertaHubSubtitle(String? freshness) {
  const base = 'Gatilho, valor e copy da oferta';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String ofertaStatusLabel({required bool ativo}) => ativo ? 'Ativa' : 'Pausada';

String ofertaSectionTitle({required bool ativo}) =>
    ativo ? 'Ativas' : 'Pausadas';
