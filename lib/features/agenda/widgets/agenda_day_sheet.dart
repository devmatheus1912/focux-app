import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_day_lane.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_slots.dart';
import 'agenda_event_card.dart';

/// Folha do dia tocado no mês: horários, intervalos livres e o botão de
/// agendar. Lê [agendamentos] ao vivo para refletir o pull-to-refresh.
class AgendaDaySheet extends StatelessWidget {
  const AgendaDaySheet({
    super.key,
    required this.day,
    required this.agendamentos,
    required this.photoFor,
    required this.onRefresh,
    required this.onOpen,
    required this.onNew,
  });

  final DateTime day;
  final ValueListenable<List<Agendamento>> agendamentos;
  final String? Function(int alunoId) photoFor;
  final Future<void> Function() onRefresh;
  final ValueChanged<Agendamento> onOpen;

  /// Início e duração sugeridos pela lacuna; nulos agendam no dia sem hora.
  final void Function(DateTime? inicio, int? duracaoMin) onNew;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final pastDay = agendaDayIsPast(day);

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: ValueListenableBuilder<List<Agendamento>>(
        valueListenable: agendamentos,
        builder: (context, all, _) {
          final daily = agendaEventsOn(all, day);
          final visible = agendaVisibleEvents(daily);
          final lane = agendaBuildDayLane(daily);
          final cancelled = agendaCancelledCount(daily);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: agendaDayHeading(
                  weekdayLabel: agendaWeekdayShort(day.weekday),
                  date: day,
                  visibleCount: 0,
                ),
                subtitle:
                    visible.isEmpty
                        ? s.agendaDiaLivre
                        : visible.length == 1
                        ? '1 atendimento'
                        : '${visible.length} atendimentos',
              ),
              const SizedBox(height: TokensStrip.s3),
              Flexible(
                child: RefreshIndicator(
                  color: primary,
                  onRefresh: onRefresh,
                  child: ListView(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      if (visible.isEmpty)
                        FxEmptyState(
                          icon: 'calendar',
                          title: s.agendaDiaLivre,
                          subtitle: agendaEmptyDayHint(),
                          quiet: true,
                        )
                      else
                        for (final item in lane)
                          switch (item) {
                            AgendaLaneGap() => _gapTile(item),
                            AgendaLaneEvent(:final agendamento, :final next) =>
                              AgendaEventCard(
                                agendamento: agendamento,
                                photoUrl: photoFor(agendamento.alunoId),
                                emphasized: next,
                                onTap: () => onOpen(agendamento),
                              ),
                          },
                      if (cancelled > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: TokensStrip.s2),
                          child: Text(
                            cancelled == 1
                                ? '1 horário cancelado oculto'
                                : '$cancelled horários cancelados ocultos',
                            textAlign: TextAlign.center,
                            style: FocuxHubTypography.bodyMuted(
                              color: chrome.mute,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s3),
              if (pastDay)
                Text(
                  s.agendaDiaPassado,
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.bodyMuted(
                    color: chrome.mute,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                FxLiquidPrimaryButton(
                  label: s.agendaAgendarNoDia(agendaDayShortLabel(day)),
                  icon: Icons.add_rounded,
                  onPressed: () => onNew(null, null),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _gapTile(AgendaLaneGap gap) {
    final seed = agendaGapSeed(gap);
    return AgendaGapTile(
      label: agendaGapLabel(gap.duration),
      onTap: seed == null ? null : () => onNew(seed.inicio, seed.duracaoMin),
    );
  }
}

class AgendaGapTile extends StatelessWidget {
  const AgendaGapTile({super.key, required this.label, this.onTap});

  final String label;

  /// Nulo quando a lacuna já passou ou não comporta 30 min.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    return FxSatelliteListTile(
      title: label,
      subtitle: const Text('Horário livre'),
      muted: onTap == null,
      trailing:
          onTap == null
              ? null
              : Text(
                'Encaixar',
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
      onTap: onTap,
    );
  }
}
