import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';

/// Pílula flutuante "Hoje" quando o dia selecionado não é hoje.
class AgendaTodayPill extends StatelessWidget {
  const AgendaTodayPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: s.agendaIrParaHoje,
      child: Material(
        color: primary,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.today_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: TokensStrip.s1),
                  Text(
                    s.agendaHoje,
                    style: FocuxHubTypography.body(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
