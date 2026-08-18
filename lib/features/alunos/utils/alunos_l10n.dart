import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

extension AlunosL10n on BuildContext {
  S get alunosL10n =>
      Localizations.of<S>(this, S) ?? lookupS(Localizations.localeOf(this));
}
