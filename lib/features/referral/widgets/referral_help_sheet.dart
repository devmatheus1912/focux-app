import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../l10n/app_localizations.dart';

Future<void> showReferralHelpSheet(BuildContext context) {
  final l10n = S.of(context);
  return showFxHelpSheet(
    context,
    title: l10n.referralHelpTooltip,
    subtitle: l10n.referralHelpSubtitle,
    tips: [
      FxHelpTip(l10n.referralHelpCodeTitle, l10n.referralHelpCodeBody, icon: 'users'),
      FxHelpTip(l10n.referralHelpInviteTitle, l10n.referralHelpInviteBody, icon: 'spark'),
      FxHelpTip(l10n.referralHelpRulesTitle, l10n.referralHelpRulesBody, icon: 'lock'),
    ],
  );
}
