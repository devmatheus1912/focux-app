import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../l10n/app_localizations.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';

/// Filtro com que a lista abre: quem tem atraso vê o atraso primeiro.
MensalidadeFiltro financeiroFiltroInicial({required int quantidadeAtrasadas}) =>
    quantidadeAtrasadas > 0
        ? MensalidadeFiltro.atrasadas
        : MensalidadeFiltro.abertas;

/// Quantos dias a cobrança está vencida; 0 se vence hoje ou ainda não venceu.
/// Sem vencimento, vale o primeiro dia do mês de referência (regra do servidor).
int financeiroDiasDeAtraso({
  required String mesReferencia,
  String? vencimento,
  required DateTime hoje,
}) {
  final base =
      financeiroParseIsoDate(vencimento) ??
      financeiroParseIsoDate(mesReferencia);
  if (base == null) return 0;
  final dia = DateTime(hoje.year, hoje.month, hoje.day);
  final diff = dia.difference(base).inDays;
  return diff > 0 ? diff : 0;
}

/// O que o "Recebido" do mês inclui além das mensalidades do próprio mês:
/// "Inclui R$ 200,00 pagos de meses anteriores e R$ 50,00 pago adiantado".
/// Nulo quando não há o que explicar. O servidor soma o recebido pela data do
/// pagamento (`MensalidadeService.resumoMensal`), por isso as duas partes.
String? financeiroNotaDoRecebido(S s, ResumoMensal r) {
  final partes = [
    if (r.recebidoDeMesesAnteriores.cents > 0)
      s.financeiroIncluiAnteriores(r.recebidoDeMesesAnteriores.formatCobranca()),
    if (r.recebidoAdiantado.cents > 0)
      s.financeiroIncluiAdiantado(r.recebidoAdiantado.formatCobranca()),
  ];
  return partes.isEmpty ? null : s.financeiroRecebidoInclui(partes.join(' e '));
}

/// Selo de estado da mensalidade: o que aconteceu, não o código do status.
({String texto, FxPillTone tom}) financeiroSelo(
  S s,
  Mensalidade m, {
  required DateTime hoje,
}) {
  switch (m.status.trim().toUpperCase()) {
    case 'PAGO':
      final pago = DateTime.tryParse(m.pagoEm ?? '');
      final data =
          pago == null
              ? ''
              : '${pago.day.toString().padLeft(2, '0')}/'
                  '${pago.month.toString().padLeft(2, '0')}';
      return (
        texto:
            data.isEmpty
                ? s.financeiroFiltroPagas
                : s.financeiroSeloPagaEm(data),
        tom: FxPillTone.success,
      );
    case 'CANCELADO':
      return (texto: s.financeiroSeloCancelada, tom: FxPillTone.neutral);
    case 'ATRASADO':
      final dias = financeiroDiasDeAtraso(
        mesReferencia: m.mesReferencia,
        vencimento: m.vencimento,
        hoje: hoje,
      );
      return (
        texto: s.financeiroSeloAtrasadaHa(dias < 1 ? 1 : dias),
        tom: FxPillTone.danger,
      );
    default:
      return (texto: s.financeiroSeloPendente, tom: FxPillTone.accent);
  }
}

/// Estado da linha: "vence 12/11", "vence hoje", "atrasada há 3 dias",
/// "paga em 05/11", "cancelada".
String financeiroMensalidadeEstado(Mensalidade m, {required DateTime hoje}) {
  switch (m.status) {
    case 'PAGO':
      final pago = DateTime.tryParse(m.pagoEm ?? '');
      return pago == null ? 'paga' : 'paga em ${dataCurta(pago)}';
    case 'CANCELADO':
      return 'cancelada';
    case 'ATRASADO':
      final dias = financeiroDiasDeAtraso(
        mesReferencia: m.mesReferencia,
        vencimento: m.vencimento,
        hoje: hoje,
      );
      return dias <= 1 ? 'atrasada desde ontem' : 'atrasada há $dias dias';
    default:
      final v = financeiroParseIsoDate(m.vencimento) ??
          financeiroParseIsoDate(m.mesReferencia);
      if (v == null) return 'em aberto';
      final dia = DateTime(hoje.year, hoje.month, hoje.day);
      return v == dia ? 'vence hoje' : 'vence ${dataCurta(v)}';
  }
}
