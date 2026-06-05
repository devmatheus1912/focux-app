part of 'aluno_detail_screen.dart';

class _AlunoOperationalStatusSection extends ConsumerWidget {
  const _AlunoOperationalStatusSection({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.aderenciaSemanal,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final List<Map<String, dynamic>>? aderenciaSemanal;

  List<({double checkins, String? date})> _aderenciaPoints(
    List<Map<String, dynamic>> raw,
  ) {
    return raw
        .map(
          (point) => (
            checkins: (point['checkins'] as num?)?.toDouble() ?? 0,
            date: point['data'] as String?,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final configAsync = ref.watch(alertasConfigProvider);
    final diasLimite =
        configAsync.valueOrNull?.diasSemTreino ??
        AlunoFollowUpStore.diasSemTreinoLimite;
    final points =
        aderenciaSemanal == null ? const <({double checkins, String? date})>[]
            : _aderenciaPoints(aderenciaSemanal!);
    final aderenciaColor = EagleTokens.aderenciaColor(
      (aluno.aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );
    final riscoColor =
        aluno.emRisco
            ? (isDark ? const Color(0xFFFFB77A) : EagleTokens.warn)
            : (isDark ? const Color(0xFF6FE296) : EagleTokens.good);
    final proximoContato = formatProximoContato(aluno);
    final neutralIdle =
        isDark
            ? const Color(0xFF374151).withValues(alpha: 0.35)
            : const Color(0xFFE5E7EB);

    return Container(
      key: const ValueKey('aluno360_operacao_status'),
      decoration: fxListCardDecoration(context),
      padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Status operacional',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Próximo contato: $proximoContato',
            style: Aluno360Layout.captionStyle(context),
          ),
          const SizedBox(height: 12),
          OperationalMetricTile(
            label:
                aluno.emRisco
                    ? 'Foco do dia'
                    : aluno.aderenciaPercent != null
                        ? 'Aderência semanal'
                        : 'Prontidão',
            value:
                aluno.emRisco
                    ? formatRiscoNivel(aluno.riscoNivel)
                    : aluno.aderenciaPercent != null
                        ? '${aluno.aderenciaPercent}%'
                        : aluno.scoreProntidao == null
                            ? '—'
                            : '${aluno.scoreProntidao}',
            hint:
                aluno.emRisco
                    ? 'Em risco · priorize contato'
                    : aluno.aderenciaPercent != null
                        ? 'Métrica dominante da semana'
                        : 'Índice operacional',
            color: aluno.emRisco ? riscoColor : aderenciaColor,
            isDark: isDark,
            leadingIcon: aluno.emRisco ? riscoMetricIcon(aluno.riscoNivel) : null,
            semanticsLabel:
                aluno.emRisco
                    ? 'Risco ${formatRiscoNivel(aluno.riscoNivel)}'
                    : aluno.aderenciaPercent != null
                        ? 'Aderência ${aluno.aderenciaPercent} por cento'
                        : 'Prontidão ${aluno.scoreProntidao ?? 'indisponível'}',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OperationalMetricTile(
                  label: 'Prontidão',
                  value:
                      aluno.scoreProntidao == null
                          ? '—'
                          : '${aluno.scoreProntidao}',
                  hint: 'Índice operacional',
                  color: primary,
                  isDark: isDark,
                  semanticsLabel:
                      'Prontidão ${aluno.scoreProntidao ?? 'indisponível'}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OperationalMetricTile(
                  label: 'Aderência',
                  value:
                      aluno.aderenciaPercent == null
                          ? '—'
                          : '${aluno.aderenciaPercent}%',
                  hint: 'Semana atual',
                  color: aderenciaColor,
                  isDark: isDark,
                  semanticsLabel:
                      aluno.aderenciaPercent == null
                          ? 'Aderência indisponível'
                          : 'Aderência ${aluno.aderenciaPercent} por cento',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OperationalMetricTile(
                  label: 'Sem treino',
                  value:
                      aluno.diasSemTreino == null
                          ? '—'
                          : '${aluno.diasSemTreino}d',
                  hint: 'Dias parados',
                  color:
                      (aluno.diasSemTreino ?? 0) >= diasLimite
                          ? EagleTokens.warn
                          : mute,
                  isDark: isDark,
                  semanticsLabel:
                      aluno.diasSemTreino == null
                          ? 'Sem treino indisponível'
                          : 'Sem treino ${aluno.diasSemTreino} dias',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OperationalMetricTile(
                  label: 'Risco',
                  value: formatRiscoNivel(aluno.riscoNivel),
                  hint: aluno.emRisco ? 'Em risco' : 'Estável',
                  color: riscoColor,
                  isDark: isDark,
                  leadingIcon: riscoMetricIcon(aluno.riscoNivel),
                  semanticsLabel:
                      'Risco ${formatRiscoNivel(aluno.riscoNivel)}',
                ),
              ),
            ],
          ),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: aderenciaColor.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: aderenciaColor.withValues(alpha: isDark ? 0.22 : 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Aderência · últimos 7 dias',
                          style: Aluno360Layout.metaStyle(context).copyWith(
                            color: ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        points.every((p) => p.checkins <= 0)
                            ? 'Sem check-ins'
                            : '${points.fold<double>(0, (a, p) => a + p.checkins).round()} check-ins',
                        style: Aluno360Layout.metaStyle(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Check-ins dos últimos 7 dias',
                    child: _AdherenceWeekBars(
                      points: points,
                      activeColor: aderenciaColor,
                      idleColor: neutralIdle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdherenceWeekBars extends StatelessWidget {
  const _AdherenceWeekBars({
    required this.points,
    required this.activeColor,
    required this.idleColor,
  });

  final List<({double checkins, String? date})> points;
  final Color activeColor;
  final Color idleColor;

  static const _barMaxHeight = 34.0;
  static const _minFraction = 0.14;

  @override
  Widget build(BuildContext context) {
    final maxVal = points.fold<double>(
      1,
      (prev, p) => p.checkins > prev ? p.checkins : prev,
    );
    final mute = fxScreenMute(context);
    final labelBand =
        14.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

    return SizedBox(
      height: _barMaxHeight + labelBand,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: _AdherenceWeekBar(
                value: points[i].checkins,
                dayLabel: weekdayLetterFromIso(points[i].date),
                maxVal: maxVal,
                activeColor: activeColor,
                idleColor: idleColor,
                labelColor: mute,
                barMaxHeight: _barMaxHeight,
                labelBand: labelBand,
                minFraction: _minFraction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdherenceWeekBar extends StatelessWidget {
  const _AdherenceWeekBar({
    required this.value,
    required this.dayLabel,
    required this.maxVal,
    required this.activeColor,
    required this.idleColor,
    required this.labelColor,
    required this.barMaxHeight,
    required this.labelBand,
    required this.minFraction,
  });

  final double value;
  final String dayLabel;
  final double maxVal;
  final Color activeColor;
  final Color idleColor;
  final Color labelColor;
  final double barMaxHeight;
  final double labelBand;
  final double minFraction;

  @override
  Widget build(BuildContext context) {
    final hasActivity = value > 0;
    final fraction =
        hasActivity
            ? (value / maxVal).clamp(minFraction, 1.0)
            : minFraction;
    final semanticsValue =
        hasActivity
            ? '${value.round()} check-in${value == 1 ? '' : 's'}'
            : 'Sem check-in';

    return Semantics(
      label:
          dayLabel.isEmpty
              ? semanticsValue
              : '$dayLabel · $semanticsValue',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: barMaxHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: barMaxHeight * fraction,
                decoration: BoxDecoration(
                  color: hasActivity ? activeColor : idleColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(
            height: labelBand,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
