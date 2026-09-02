import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../utils/agenda_schedule.dart';

class AgendaHubHeader extends StatelessWidget {
  const AgendaHubHeader({
    super.key,
    required this.freshnessLabel,
    required this.onHelp,
    required this.onIcal,
    this.onToday,
    this.onNew,
  });

  final String? freshnessLabel;
  final VoidCallback onHelp;
  final VoidCallback onIcal;
  final VoidCallback? onToday;
  final VoidCallback? onNew;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = dashboardReadableCaption(context, isDark: chrome.isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: DecoratedBox(
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.04,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  label: [
                    'Agenda',
                    if (freshnessLabel != null && freshnessLabel!.isNotEmpty)
                      freshnessLabel!,
                  ].join('. '),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agenda',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dashboardPageTitleStyle(context, color: ink),
                      ),
                      if (freshnessLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          freshnessLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: mute,
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: TokensStrip.s2),
              FxHelpIconButton(
                tooltip: 'Como usar a agenda',
                onTap: onHelp,
              ),
              const SizedBox(width: FxHelpChrome.gap),
              ShellHeaderIconButton(
                icon: 'calendar',
                size: FxHelpChrome.iconSize,
                tooltip: 'Exportar iCal',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onIcal();
                },
              ),
              if (onToday != null) ...[
                const SizedBox(width: FxHelpChrome.gap),
                Semantics(
                  button: true,
                  label: 'Ir para hoje',
                  child: Tooltip(
                    message: 'Ir para hoje',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onToday!();
                        },
                        borderRadius: BorderRadius.circular(
                          FxHelpChrome.iconSize / 2,
                        ),
                        child: Container(
                          width: FxHelpChrome.iconSize,
                          height: FxHelpChrome.iconSize,
                          decoration: chrome.headerAction(
                            radius: FxHelpChrome.iconSize / 2,
                          ),
                          child: Icon(
                            Icons.today_outlined,
                            color: primary,
                            size: FxHelpChrome.iconSize * 0.48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (onNew != null) ...[
                const SizedBox(width: FxHelpChrome.gap),
                ShellHeaderIconButton(
                  icon: 'plus',
                  size: FxHelpChrome.iconSize,
                  tooltip: 'Novo agendamento',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onNew!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AgendaWeekBar extends StatelessWidget {
  const AgendaWeekBar({
    super.key,
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final end = weekStart.add(const Duration(days: 6));
    final label =
        '${weekStart.day}–${end.day} ${agendaMonthShort[weekStart.month]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Semana anterior',
            onPressed: () {
              HapticFeedback.selectionClick();
              onPrev();
            },
            constraints: const BoxConstraints(
              minWidth: FxHomeSheetChrome.touchTarget,
              minHeight: FxHomeSheetChrome.touchTarget,
            ),
            icon: Icon(Icons.chevron_left, color: chrome.mute),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
            ),
          ),
          IconButton(
            tooltip: 'Próxima semana',
            onPressed: () {
              HapticFeedback.selectionClick();
              onNext();
            },
            constraints: const BoxConstraints(
              minWidth: FxHomeSheetChrome.touchTarget,
              minHeight: FxHomeSheetChrome.touchTarget,
            ),
            icon: Icon(Icons.chevron_right, color: chrome.mute),
          ),
        ],
      ),
    );
  }
}
