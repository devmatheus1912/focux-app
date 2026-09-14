import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../data/checkin_repository.dart';

/// Fallback when personal-authored "erros comuns" arrives in English.
const checkinErrosComunsFallback =
    'Peça orientação ao personal se tiver dúvida na execução.';

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

String checkinErrosComunsBody(String? errosComuns) {
  final t = errosComuns?.trim() ?? '';
  if (t.isEmpty) return '';
  if (checkinTextLooksNonPtBr(t)) return checkinErrosComunsFallback;
  return t;
}

Future<void> showCheckinExerciseTipsSheet(
  BuildContext context, {
  required ExecucaoExercicio ee,
}) {
  final tips = <FxHelpTip>[
    if (ee.observacoes?.trim().isNotEmpty == true)
      FxHelpTip('Observação', ee.observacoes!.trim(), icon: 'file-text'),
    if (ee.errosComuns?.trim().isNotEmpty == true)
      FxHelpTip(
        'Erros comuns',
        checkinErrosComunsBody(ee.errosComuns),
        icon: 'alert-triangle',
      ),
    if (ee.contraindicacoes?.trim().isNotEmpty == true)
      FxHelpTip('Contraindicações', ee.contraindicacoes!.trim(), icon: 'heart'),
    if (ee.substitutos?.trim().isNotEmpty == true)
      FxHelpTip('Substitutos', ee.substitutos!.trim(), icon: 'refresh-cw'),
  ];
  if (tips.isEmpty) {
    tips.add(
      const FxHelpTip(
        'Sem dicas',
        'Este exercício não tem observação, erro comum ou substituto cadastrado.',
        icon: 'info',
      ),
    );
  }
  return showFxHelpSheet(
    context,
    title: ee.exercicioNome,
    subtitle: 'Leia e volte — o treino continua na tela.',
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
