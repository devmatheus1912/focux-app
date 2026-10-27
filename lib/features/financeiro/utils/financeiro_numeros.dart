import '../../../core/widgets/fx_status_pill.dart';
import '../../../l10n/app_localizations.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';

/// Filtro com que a lista abre: quem tem atraso vê o atraso primeiro.
MensalidadeFiltro financeiroFiltroInicial({required int quantidadeAtrasadas}) =>
    quantidadeAtrasadas > 0
        ? MensalidadeFiltro.atrasadas
        : MensalidadeFiltro.abertas;

/// Primeiro dia do mês de [hoje] no formato da API (`yyyy-MM-01`).
String financeiroMesAtualIso(DateTime hoje) =>
    financeiroIsoDate(hoje.year, hoje.month, 1);

/// Dia sugerido para o vencimento de uma mensalidade nova.
///
/// Dia 5 do mês de referência. No mês corrente, se o dia 5 já passou, vale
/// hoje + 5 dias: uma cobrança lançada agora não pode nascer atrasada.
String financeiroVencimentoSugerido({
  required String mesReferenciaIso,
  required DateTime hoje,
}) {
  final mes =
      financeiroParseIsoDate(mesReferenciaIso) ??
      DateTime(hoje.year, hoje.month, 1);
  final ultimo = DateTime(mes.year, mes.month + 1, 0).day;
  final dia5 = DateTime(mes.year, mes.month, ultimo < 5 ? ultimo : 5);
  final hojeDia = DateTime(hoje.year, hoje.month, hoje.day);
  final mesCorrente = mes.year == hoje.year && mes.month == hoje.month;
  if (mesCorrente && dia5.isBefore(hojeDia)) {
    final d = hojeDia.add(const Duration(days: 5));
    return financeiroIsoDate(d.year, d.month, d.day);
  }
  return financeiroIsoDate(dia5.year, dia5.month, dia5.day);
}

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

/// "R$ 100,00 de meses anteriores" só existe quando há o que explicar.
bool financeiroTemRecebidoAnterior(ResumoMensal r) =>
    r.recebidoDeMesesAnteriores.cents > 0;

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
