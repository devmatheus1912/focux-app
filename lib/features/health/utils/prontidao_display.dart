import '../../../core/utils/fx_utils.dart';
import '../../../l10n/app_localizations.dart';

/// Topo da escala do índice de prontidão do servidor.
const prontidaoEscalaMax = 100;

/// "Atualizado ontem" / "Atualizado em 26/09"; null quando é de hoje.
String? prontidaoFrescor(S s, DateTime? dataReferencia, DateTime now) {
  if (dataReferencia == null) return null;
  final hoje = DateTime(now.year, now.month, now.day);
  final dia = DateTime(
    dataReferencia.year,
    dataReferencia.month,
    dataReferencia.day,
  );
  final dias = (hoje.difference(dia).inHours / 24).round();
  if (dias <= 0) return null;
  if (dias == 1) return s.prontidaoAtualizadoOntem;
  return s.prontidaoAtualizadoEm(fxDateShort(dia));
}
