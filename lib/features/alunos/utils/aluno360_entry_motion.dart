import 'package:flutter/material.dart';

import '../../../core/utils/motion_preferences.dart';

Duration aluno360MotionDuration(BuildContext context) {
  if (reduceMotionOf(context)) return Duration.zero;
  return const Duration(milliseconds: 220);
}

Duration aluno360TabSwitchDuration(BuildContext context) {
  if (reduceMotionOf(context)) return Duration.zero;
  return const Duration(milliseconds: 150);
}

Duration aluno360EntranceDelay(int step, {bool tablet = false}) {
  final baseMs = tablet ? 60 : 40;
  return Duration(milliseconds: step * baseMs);
}
