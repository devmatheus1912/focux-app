import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_day_lane.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_slots.dart';
import '../utils/agenda_status.dart';
import 'agenda_event_card.dart';

/// Faixa da semana: cada dia com a contagem, setas trocam de semana.
class AgendaSemanaFaixa extends StatelessWidget {
  const AgendaSemanaFaixa({
    super.key,
    required this.dia,
    required this.porDia,
    required this.onDia,
    this.now,
  });

  final DateTime dia;
  final Map<String, List<Agendamento>> porDia;
  final ValueChanged<DateTime> onDia;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final hoje = now ?? DateTime.now();
    final segunda = agendaSegundaDaSemana(dia);
    return Row(
      children: [
        IconButton(
          tooltip: s.agendaSemanaAnterior,
          onPressed: () => onDia(dia.subtract(const Duration(days: 7))),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final d = DateTime(segunda.year, segunda.month, segunda.day + i);
                final selecionado = agendaSameDay(d, dia);
                final eHoje = agendaSameDay(d, hoje);
                final n = porDia[agendaIsoDate(d)]?.length ?? 0;
                final cor = selecionado ? onPrimary : chrome.ink;
                return Semantics(
                  button: true,
                  selected: selecionado,
                  label: agendaMonthDayA11y(day: d, count: n, isToday: eHoje),
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TokensStrip.s3),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onDia(d);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      decoration: BoxDecoration(
                        color: selecionado ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(TokensStrip.s3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            agendaWeekdayInitials[i],
                            style: FocuxHubTypography.bodyMuted(
                              color: selecionado ? onPrimary : chrome.mute,
                            ),
                          ),
                          Text(
                            '${d.day}',
                            style: FocuxHubTypography.cardTitle(
                              color: eHoje && !selecionado ? primary : cor,
                            ),
                          ),
                          Text(
                            n == 0 ? ' ' : '$n',
                            style: FocuxHubTypography.bodyMuted(
                              color: selecionado ? onPrimary : primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        IconButton(
          tooltip: s.agendaProximaSemana,
          onPressed: () => onDia(dia.add(const Duration(days: 7))),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Lista do dia, sem folha: atendimentos e horários livres entre eles.
class AgendaDiaLista extends StatelessWidget {
  const AgendaDiaLista({
    super.key,
    required this.dia,
    required this.agendamentos,
    required this.photoFor,
    required this.onRefresh,
    required this.onOpen,
    required this.onNew,
    required this.onPresenca,
    this.now,
  });

  final DateTime dia;
  final List<Agendamento> agendamentos;
  final String? Function(int alunoId) photoFor;
  final Future<void> Function() onRefresh;
  final ValueChanged<Agendamento> onOpen;
  final void Function(DateTime? inicio, int? duracaoMin) onNew;
  final void Function(Agendamento ag, bool veio) onPresenca;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final agora = now ?? DateTime.now();
    final passado = agendaDayIsPast(dia, now: agora);
    final doDia = agendaEventsOn(agendamentos, dia);
    final visiveis = agendaVisibleEvents(doDia);
    final canceladas = agendaCancelledCount(doDia);
    return RefreshIndicator(
      color: primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          TokensStrip.s4,
        ),
        children: [
          if (visiveis.isEmpty)
            FxEmptyState(
              icon: 'calendar',
              title: passado ? s.agendaDiaPassadoVazio : s.agendaDiaLivre,
              subtitle: passado ? null : agendaEmptyDayHint(),
              quiet: true,
            )
          else
            for (final item in agendaBuildDayLane(doDia, now: agora))
              switch (item) {
                AgendaLaneGap() => _gap(item, agora),
                AgendaLaneEvent(:final agendamento, :final next) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AgendaEventCard(
                      agendamento: agendamento,
                      photoUrl: photoFor(agendamento.alunoId),
                      emphasized: next,
                      detalheExtra:
                          next ? agendaTempoAteTexto(agendamento.inicio, agora) : null,
                      onTap: () => onOpen(agendamento),
                    ),
                    if (agendaPrecisaPresenca(agendamento, now: agora))
                      Padding(
                        padding: const EdgeInsets.only(
                          left: TokensStrip.s2,
                          bottom: TokensStrip.s2,
                        ),
                        child: Wrap(
                          spacing: TokensStrip.s2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FxTonalButton(
                              label: s.agendaVeio,
                              compact: true,
                              onPressed: () => onPresenca(agendamento, true),
                            ),
                            FxTonalButton(
                              label: s.agendaFaltou,
                              compact: true,
                              onPressed: () => onPresenca(agendamento, false),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              },
          if (canceladas > 0)
            Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Text(
                canceladas == 1
                    ? '1 horário cancelado oculto'
                    : '$canceladas horários cancelados ocultos',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!passado) ...[
            const SizedBox(height: TokensStrip.s3),
            FxTonalButton(
              label: s.agendaAgendarNoDia(agendaDayShortLabel(dia)),
              icon: Icons.add_rounded,
              expanded: true,
              onPressed: () => onNew(null, null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _gap(AgendaLaneGap gap, DateTime agora) {
    final seed = agendaGapSeed(gap, now: agora);
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
      titleCase: false,
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
