import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

extension AlunosL10n on BuildContext {
  S get alunosL10n {
    try {
      final fromTree = Localizations.of<S>(this, S);
      if (fromTree != null) return fromTree;
    } catch (_) {}
    try {
      return lookupS(Localizations.localeOf(this));
    } catch (_) {
      return lookupS(const Locale('pt'));
    }
  }
}
