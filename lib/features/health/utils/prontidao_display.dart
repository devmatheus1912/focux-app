import '../../../core/utils/fx_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../data/health_repository.dart';

/// Topo da escala do índice de prontidão do servidor.
const prontidaoEscalaMax = 100;

/// Índice de 0 a 100, não porcentagem: "77/100". Ausente: "--".
String prontidaoNota(int? score) =>
    score == null ? '--' : '$score/$prontidaoEscalaMax';

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

/// Label do card da Home. Sem nota do servidor, só "indisponível": nível e
/// dica sem o índice não valem como conselho.
String alunoProntidaoSemantica(
  S s,
  RecoverySnapshot snap, {
  required bool mostrarDica,
  String? frescor,
}) {
  final score = snap.recoveryScore;
  final partes = [
    if (score == null)
      s.saudeProntidaoIndisponivelSemantics
    else
      s.saudeProntidaoSemantics(score, snap.recoveryLabel),
    if (score != null && mostrarDica) snap.recoveryHint,
    if (frescor != null) frescor,
  ];
  return '${[
    for (final p in partes)
      if (p.trim().isNotEmpty) p.trim().replaceFirst(RegExp(r'\.+$'), ''),
  ].join('. ')}.';
}
