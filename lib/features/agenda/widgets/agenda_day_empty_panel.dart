import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/agenda_schedule.dart';
import '../../dashboard/utils/dashboard_readability.dart';

class AgendaDayEmptyPanel extends StatelessWidget {
  const AgendaDayEmptyPanel({
    super.key,
    required this.dayLabel,
    required this.onNew,
  });

  final String dayLabel;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = dashboardReadableCaption(context, isDark: chrome.isDark);

    return Semantics(
      container: true,
      label: '$dayLabel. Dia livre. ${agendaEmptyDayHint()}',
      child: DecoratedBox(
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.04,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(
                        alpha: chrome.isDark ? 0.18 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: FxIcon(name: 'calendar', size: 22, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dashboardPageTitleStyle(
                            context,
                            color: chrome.ink,
                          ).copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dia livre',
                          style: FocuxHubTypography.cardTitle(color: chrome.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          agendaEmptyDayHint(),
                          style: FocuxHubTypography.bodyMuted(
                            color: mute,
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: 12.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: 'Novo agendamento',
                child: FxLiquidPrimaryButton(
                  label: 'Novo agendamento',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onNew();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
