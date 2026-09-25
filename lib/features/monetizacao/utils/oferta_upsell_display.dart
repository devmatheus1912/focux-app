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

String ofertaHubSubtitle(String? freshness, {int? ativas, int? pausadas}) {
  final base = ofertaContagemLabel(ativas: ativas, pausadas: pausadas);
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

/// "2 ativas · 1 pausada" — antes de carregar, só o nome da vitrine.
String ofertaContagemLabel({int? ativas, int? pausadas}) {
  if (ativas == null || pausadas == null) return 'Ofertas';
  if (ativas == 0 && pausadas == 0) return 'Nenhuma oferta';
  final parts = <String>[
    if (ativas > 0) ativas == 1 ? '1 ativa' : '$ativas ativas',
    if (pausadas > 0) pausadas == 1 ? '1 pausada' : '$pausadas pausadas',
  ];
  return parts.join(' · ');
}

String ofertaStatusLabel({required bool ativo}) => ativo ? 'Ativa' : 'Pausada';

String ofertaSectionTitle({required bool ativo}) =>
    ativo ? 'Ativas' : 'Pausadas';

String ofertaStickyCtaLabel() => 'Nova oferta';

String ofertaEnviarTooltip() => 'Enviar para um aluno';

String ofertaEnviarPickerTitle() => 'Enviar para qual aluno?';

String ofertaSemAlunos() => 'Cadastre um aluno antes de enviar ofertas.';

String ofertaEnviarConfirmTitle(String nome) => 'Enviar para $nome?';

String ofertaEnviarConfirmMessage(String titulo) =>
    '"$titulo" aparece no app do aluno até ele aceitar ou recusar.';

String ofertaEnviarSuccess({required bool pushEntregue}) =>
    pushEntregue
        ? 'Oferta enviada com notificação'
        : 'Oferta enviada. O aluno vê ao abrir o app (sem notificação no celular).';

/// Hint sob a lista quando há poucas ofertas (evita vazio flutuando).
String? ofertaSparseHint({required int count, int? ativas}) {
  if (count <= 0) return null;
  if (ativas == 0) {
    return 'Todas pausadas. Reative uma para o aluno voltar a ver ofertas.';
  }
  if (count == 1) {
    return 'Só uma oferta. Crie outra para check-in ou trilha e cubra mais momentos.';
  }
  if (count < 3) {
    return 'Poucas ofertas. Novas cobrem mais gatilhos na jornada do aluno.';
  }
  return null;
}

/// Folga inferior da lista quando o sticky CTA está fora do scroll.
double ofertaListBottomPad({required bool stickyVisible}) =>
    stickyVisible ? 8 : 24;
