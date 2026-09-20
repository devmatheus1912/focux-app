import '../../../core/money/fx_money.dart';
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

String ofertaValorLabel(Object valor) =>
    valor is FxMoney ? valor.format() : formatBrlCurrency(valor as num);

String ofertaHubSubtitle(String? freshness) {
  const base = 'Ofertas ativas';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String ofertaStatusLabel({required bool ativo}) => ativo ? 'Ativa' : 'Pausada';

String ofertaSectionTitle({required bool ativo}) =>
    ativo ? 'Ativas' : 'Pausadas';

String ofertaStickyCtaLabel() => 'Nova oferta';

/// Hint sob a lista quando há poucas ofertas (evita vazio flutuando).
String? ofertaSparseHint({required int count}) {
  if (count <= 0) return null;
  if (count == 1) {
    return 'Só uma ativa. Crie outra para check-in ou trilha e preencha o espaço.';
  }
  if (count < 3) {
    return 'Poucas ofertas. Novas cobrem mais gatilhos na jornada do aluno.';
  }
  return null;
}

/// Folga inferior da lista quando o sticky CTA está fora do scroll.
double ofertaListBottomPad({required bool stickyVisible}) =>
    stickyVisible ? 8 : 24;
