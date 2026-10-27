import '../../../core/money/fx_money.dart';
import '../../../l10n/app_localizations.dart';

/// Valor sugerido na folha: o da última mensalidade do aluno. Sem histórico
/// (ou valor zerado), nada: o campo fica vazio, nunca com um número inventado.
FxMoney? recorrenciaValorSugerido(FxMoney? ultimaMensalidade) =>
    ultimaMensalidade != null && ultimaMensalidade.isPositive
    ? ultimaMensalidade
    : null;

/// Valor digitado, ou nulo se vazio, inválido ou zero.
FxMoney? recorrenciaLerValor(String texto) {
  if (texto.trim().isEmpty) return null;
  try {
    final v = FxMoney.fromInput(texto);
    return v.isPositive ? v : null;
  } on FormatException {
    return null;
  }
}

/// "Todo dia 26 · R$ 199,00 · PIX".
String recorrenciaResumo(S s, {required int dia, required FxMoney valor}) =>
    s.recorrenciaResumo(dia, valor.formatCobranca());

/// Os filtros só existem quando há o que filtrar: com a lista vazia e sem
/// busca nem filtro, só o convite para criar a primeira.
bool recorrenciaMostrarFiltros({
  required bool temItens,
  required bool filtroAtivo,
  required bool buscaAtiva,
}) => temItens || filtroAtivo || buscaAtiva;
