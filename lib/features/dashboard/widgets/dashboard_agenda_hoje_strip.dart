import 'package:flutter/material.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../data/command_center_data.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';

/// Strip compacto: próximos compromissos de hoje (BFF agendaHoje).
class DashboardAgendaHojeStrip extends StatelessWidget {
  const DashboardAgendaHojeStrip({
    super.key,
    required this.items,
    required this.isDark,
    required this.primary,
  });

  final List<AgendamentoResumo> items;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final visible = items.take(3).toList(growable: false);
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DashboardMicrocopy.agendaHoje,
                style: dashboardSectionTitleStyle(context, color: heading),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => goPersonalShellTab(context, '/agenda'),
                child: Text(DashboardMicrocopy.verAgenda),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...visible.map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                button: true,
                label:
                    '${a.horario}. ${a.nomeAluno}. Status ${a.status}. Abrir agenda',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => goPersonalShellTab(context, '/agenda'),
                    borderRadius: BorderRadius.circular(TokensStrip.rCard),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(TokensStrip.rCard),
                        border: Border.all(
                          color: primary.withValues(alpha: isDark ? 0.28 : 0.18),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          FxIcon(
                            name: 'calendar',
                            size: 18,
                            color: BrandPalette.sectionAccent(primary, dark: isDark),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${a.horario} · ${a.nomeAluno}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dashboardCardTitleStyle(ink),
                            ),
                          ),
                          Text(
                            a.status,
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
