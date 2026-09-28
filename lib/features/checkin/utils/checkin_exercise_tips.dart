import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';

const _enStopwords = {
  'the',
  'and',
  'with',
  'from',
  'your',
  'you',
  'are',
  'for',
  'that',
  'this',
  'into',
  'keep',
  'avoid',
  'dont',
  "don't",
  'not',
  'too',
  'much',
  'while',
  'during',
  'make',
  'sure',
  'through',
};

const _enExerciseCues = {
  'elbows',
  'elbow',
  'shoulder',
  'shoulders',
  'knees',
  'knee',
  'hips',
  'hip',
  'back',
  'locking',
  'lock',
  'breathe',
  'core',
  'weight',
  'body',
  'down',
  'up',
  'reps',
  'set',
  'sets',
  'form',
  'stance',
  'grip',
};

/// Heuristic: English stopwords / cues vs Portuguese (accents).
bool checkinTextLooksNonPtBr(String text) {
  final raw = text.trim();
  if (raw.isEmpty) return false;
  final lower = raw.toLowerCase();
  final tokens =
      lower
          .split(RegExp(r"[^a-z0-9à-ü']+", caseSensitive: false))
          .where((t) => t.length >= 2)
          .toList();
  if (tokens.isEmpty) return false;

  final enHits = tokens.where(_enStopwords.contains).length;
  final ratio = enHits / tokens.length;
  if (ratio >= 0.18 || enHits >= 3) return true;

  final hasPtAccent = RegExp(
    r'[àáâãäéêíóôõúüç]',
    caseSensitive: false,
  ).hasMatch(raw);
  final hasEnCue = tokens.any(_enExerciseCues.contains);
  final asciiOnly = RegExp(r'^[\x00-\x7F]+$').hasMatch(raw);
  if (asciiOnly && !hasPtAccent && hasEnCue && raw.length > 40) {
    return true;
  }
  return false;
}

/// "Erros comuns" do personal em inglês viram orientação genérica em PT.
String checkinErrosComunsBody(S s, String? errosComuns) {
  final t = errosComuns?.trim() ?? '';
  if (t.isEmpty) return '';
  if (checkinTextLooksNonPtBr(t)) return s.checkinDicasFallbackErros;
  return t;
}

Future<void> showCheckinExerciseTipsSheet(
  BuildContext context, {
  required ExecucaoExercicio ee,
}) {
  final s = S.of(context);
  final tips = <FxHelpTip>[
    if (ee.observacoes?.trim().isNotEmpty == true)
      FxHelpTip(
        s.checkinDicasObservacao,
        ee.observacoes!.trim(),
        icon: 'file-text',
      ),
    if (ee.errosComuns?.trim().isNotEmpty == true)
      FxHelpTip(
        s.checkinDicasErrosComuns,
        checkinErrosComunsBody(s, ee.errosComuns),
        icon: 'alert-triangle',
      ),
    if (ee.contraindicacoes?.trim().isNotEmpty == true)
      FxHelpTip(
        s.checkinDicasContraindicacoes,
        ee.contraindicacoes!.trim(),
        icon: 'heart',
      ),
    if (ee.substitutos?.trim().isNotEmpty == true)
      FxHelpTip(
        s.checkinDicasSubstitutos,
        ee.substitutos!.trim(),
        icon: 'refresh-cw',
      ),
  ];
  if (tips.isEmpty) {
    tips.add(
      FxHelpTip(
        s.checkinDicasVazioTitulo,
        s.checkinDicasVazioTexto,
        icon: 'info',
      ),
    );
  }
  return showFxHelpSheet(
    context,
    title: ee.exercicioNome,
    subtitle: s.checkinDicasSub,
    tips: tips,
  );
}

bool checkinExerciseHasTips(ExecucaoExercicio ee) {
  // Count errosComuns even when EN (sheet shows PT fallback).
  return ee.observacoes?.trim().isNotEmpty == true ||
      ee.errosComuns?.trim().isNotEmpty == true ||
      ee.contraindicacoes?.trim().isNotEmpty == true ||
      ee.substitutos?.trim().isNotEmpty == true;
}

bool checkinExerciseHasDemo(ExecucaoExercicio ee) {
  return ee.gifUrl?.isNotEmpty == true ||
      ee.videoUrl?.isNotEmpty == true ||
      ee.thumbnailUrl?.isNotEmpty == true;
}
