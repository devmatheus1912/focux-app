import '../models/checkin_execucao_models.dart';
import 'package:flutter/painting.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../l10n/app_localizations.dart';

/// Thumb-zone minimum for S8 execution controls.
const double checkinExecutionControlMin = TokensStrip.s8;

/// Altura da faixa "N séries esperando conexão" (alvo do "Tentar agora").
const double checkinPendentesAvisoAltura = 48;

/// Fonte do texto do aviso; a reserva do rodapé escala por ela.
const double checkinPendentesAvisoFonte = TokensStrip.fontBodySm;

/// Altura do rodapé fixo (+ aviso de pendentes); snackbar flutua acima. O
/// aviso cresce com a fonte do aparelho, porque o texto dele quebra linha.
double checkinRodapeReserva({
  required bool comPendentes,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    checkinExecutionControlMin +
    TokensStrip.s2 +
    TokensStrip.s3 +
    (comPendentes ? _pendentesAvisoReserva(textScaler) : 0);

double _pendentesAvisoReserva(TextScaler textScaler) {
  final escala =
      textScaler.scale(checkinPendentesAvisoFonte) / checkinPendentesAvisoFonte;
  return checkinPendentesAvisoAltura * (escala < 1 ? 1 : escala);
}

/// Teto da mídia inline: o Registrar do rodapé nunca some atrás do vídeo.
const double checkinMediaMaxFracaoTela = 0.24;

/// Altura da mídia inline; vídeo vertical para no teto e fica com barras.
double checkinMediaAltura({
  required double largura,
  required double alturaTela,
  required double aspectRatio,
}) {
  final natural = aspectRatio > 0 ? largura / aspectRatio : largura * 9 / 16;
  final teto = alturaTela * checkinMediaMaxFracaoTela;
  return natural < teto ? natural : teto;
}

/// Prévia de altura fixa (imagem, carregando) respeitando o mesmo teto.
double checkinMediaPreviaAltura({
  required double preferida,
  required double alturaTela,
}) {
  final teto = alturaTela * checkinMediaMaxFracaoTela;
  return preferida < teto ? preferida : teto;
}

int checkinRestRemaining({required DateTime endsAt, DateTime? now}) {
  final left = endsAt.difference(now ?? DateTime.now()).inSeconds;
  return left < 0 ? 0 : left;
}

String checkinDurationLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String checkinChromeContextLine(
  S s, {
  required String duration,
  required int current,
  required int total,
}) {
  if (total <= 0) return duration;
  return s.checkinChromeContexto(duration, current, total);
}

String checkinSeriesRepsLabel(int? series, String? reps) {
  final s = series == null ? '—' : '$series';
  final r = reps == null || reps.trim().isEmpty ? '—' : reps.trim();
  return '$s × $r';
}

String? checkinCargaLabel(double? value) {
  if (value == null) return null;
  final rounded =
      value.roundToDouble() == value
          ? value.toStringAsFixed(0)
          : formatBrDecimal(value);
  return '${rounded.replaceAll('.', ',')} kg';
}

String checkinKgLabel(double value) {
  final fixed = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 1,
  );
  return fixed.replaceAll('.', ',');
}

String checkinEvolucaoTipoLabel(S s, String tipo) => switch (tipo) {
  'REPETICOES' => s.checkinEvolucaoRepeticoes,
  'VOLUME' => s.checkinEvolucaoVolume,
  _ => s.checkinEvolucaoCarga,
};

/// Com o total conhecido o botão diz qual série é; sem ele, o rótulo curto.
String checkinRegistrarLabel(
  S s, {
  required bool first,
  int? atual,
  int? total,
}) => atual != null && total != null && total > 0 && atual <= total
    ? s.checkinRegistrarSerieN(atual, total)
    : first
    ? s.checkinRegistrarSerie
    : s.checkinProximaSerie;

/// "Série 1 de 4 · 8-12 reps · 75 s": a linha do exercício na execução.
String checkinLinhaDaSerie(
  S s, {
  required int atual,
  int? total,
  String? repeticoes,
  int? descansoSegundos,
}) => [
  if (total != null && total > 0) s.checkinSerieDe(atual.clamp(1, total), total),
  if (repeticoes != null && repeticoes.trim().isNotEmpty) '${repeticoes.trim()} reps',
  if (descansoSegundos != null && descansoSegundos > 0) '$descansoSegundos s',
].join(' · ');

String checkinConfirmarRestanteLabel(
  S s, {
  required int feitas,
  required int? total,
}) {
  final left = (total ?? 0) - feitas;
  return s.checkinConfirmarRestante(left <= 1 ? 1 : left);
}

T checkinPickCurrentExercise<T>({
  required List<T> exercicios,
  required int Function(T item) idOf,
  required bool Function(T item) concluidoOf,
  int? focoId,
}) {
  if (focoId != null) {
    for (final item in exercicios) {
      if (idOf(item) == focoId) return item;
    }
  }
  return exercicios.firstWhere(
    (item) => !concluidoOf(item),
    orElse: () => exercicios.last,
  );
}

/// Anel do lockup de descanso — 3× o alvo S8, sem literal solto.
const double checkinRestRingSize = checkinExecutionControlMin * 3;

String checkinRestCountdownLabel(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final mm = safe ~/ 60;
  final ss = (safe % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

String checkinRestContextLine(
  S s, {
  required String exerciseName,
  required int seriesFeitas,
  int? series,
}) {
  final next = seriesFeitas + 1;
  final seriesPart =
      series == null || series <= 0
          ? s.checkinProximaSerie
          : s.checkinSerieNDeM(next, series);
  final name = exerciseName.trim();
  if (name.isEmpty) return seriesPart;
  return '$seriesPart · $name';
}

String checkinRestSemanticsLabel(
  S s, {
  required int seconds,
  String? contextLine,
}) {
  final time = checkinRestCountdownLabel(seconds);
  final ctx = contextLine?.trim();
  if (ctx == null || ctx.isEmpty) return s.checkinDescansoTempo(time);
  return s.checkinDescansoTempoCom(time, ctx);
}

/// Carga e reps da **última** série registrada na sessão anterior deste exercício
/// (a de maior número). Nula quando não há nada útil para repetir.
({double? cargaKg, int? reps})? ultimaVezDoExercicio(List<ExecucaoSerie> anteriores) {
  if (anteriores.isEmpty) return null;
  final ultima = anteriores.reduce((a, b) => b.numero > a.numero ? b : a);
  final reps = int.tryParse(ultima.repeticoes?.trim() ?? '');
  final carga = (ultima.cargaKg ?? 0) > 0 ? ultima.cargaKg : null;
  if (carga == null && reps == null) return null;
  return (cargaKg: carga, reps: reps);
}

