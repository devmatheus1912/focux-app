part of 'aluno_detail_screen.dart';

class _AlunoOperationalStatusSection extends ConsumerWidget {
  const _AlunoOperationalStatusSection({
    required this.alunoId,
    required this.aluno,
    required this.isDark,
    required this.primary,
  });

  final int alunoId;
  final Aluno aluno;
  final bool isDark;
  final Color primary;

  List<double> _aderenciaSparkline(List<Map<String, dynamic>> raw) {
    return raw
        .map((point) => (point['checkins'] as num?)?.toDouble() ?? 0)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final aderenciaAsync = ref.watch(alunoAderenciaSemanalProvider(alunoId));
    final sparklineData = aderenciaAsync.valueOrNull == null
        ? const <double>[]
        : _aderenciaSparkline(aderenciaAsync.valueOrNull!);
    final aderenciaColor = EagleTokens.aderenciaColor(
      (aluno.aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );
    final riscoColor =
        aluno.emRisco
            ? (isDark ? const Color(0xFFFFB77A) : EagleTokens.warn)
            : (isDark ? const Color(0xFF6FE296) : EagleTokens.good);
    final proximoContato = formatProximoContato(aluno);

    return Container(
      key: const ValueKey('aluno360_operacao_status'),
      decoration: fxListCardDecoration(context),
      padding: const EdgeInsets.all(16),
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
            'Sinais atualizados para priorizar sua ação',
            style: TextStyle(color: mute, fontSize: 11.5, height: 1.3),
          ),
          const SizedBox(height: 14),
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
                      'Aderência ${aluno.aderenciaPercent ?? 'indisponível'} por cento',
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
                      (aluno.diasSemTreino ?? 0) >=
                              AlunoFollowUpStore.diasSemTreinoLimite
                          ? EagleTokens.warn
                          : mute,
                  isDark: isDark,
                  semanticsLabel:
                      'Sem treino ${aluno.diasSemTreino ?? 'indisponível'} dias',
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
          const SizedBox(height: 8),
          OperationalMetricTile(
            label: 'Contato',
            value: proximoContato,
            hint: 'Próximo follow-up',
            color: primary,
            isDark: isDark,
            semanticsLabel: 'Próximo contato $proximoContato',
          ),
          if (aderenciaAsync.isLoading) ...[
            const SizedBox(height: 14),
            FxLoading.sectionShimmer(context, height: 52, showHeader: false),
          ] else if (sparklineData.isNotEmpty) ...[
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
                          style: TextStyle(
                            color: ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        sparklineData.every((v) => v <= 0)
                            ? 'Sem check-ins'
                            : '${sparklineData.fold<double>(0, (a, b) => a + b).round()} check-ins',
                        style: TextStyle(
                          color: mute,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Check-ins dos últimos 7 dias',
                    child: _AdherenceWeekBars(
                      checkins: sparklineData,
                      activeColor: aderenciaColor,
                      idleColor: aderenciaColor.withValues(alpha: isDark ? 0.28 : 0.2),
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
    required this.checkins,
    required this.activeColor,
    required this.idleColor,
  });

  final List<double> checkins;
  final Color activeColor;
  final Color idleColor;

  static const _barMaxHeight = 34.0;
  static const _minFraction = 0.14;

  @override
  Widget build(BuildContext context) {
    final maxVal = checkins.fold<double>(
      1,
      (prev, v) => v > prev ? v : prev,
    );

    return SizedBox(
      height: _barMaxHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < checkins.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: _AdherenceWeekBar(
                value: checkins[i],
                maxVal: maxVal,
                activeColor: activeColor,
                idleColor: idleColor,
                barMaxHeight: _barMaxHeight,
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
    required this.maxVal,
    required this.activeColor,
    required this.idleColor,
    required this.barMaxHeight,
    required this.minFraction,
  });

  final double value;
  final double maxVal;
  final Color activeColor;
  final Color idleColor;
  final double barMaxHeight;
  final double minFraction;

  @override
  Widget build(BuildContext context) {
    final hasActivity = value > 0;
    final fraction =
        hasActivity
            ? (value / maxVal).clamp(minFraction, 1.0)
            : minFraction;

    return Semantics(
      label:
          hasActivity
              ? '${value.round()} check-in${value == 1 ? '' : 's'}'
              : 'Sem check-in',
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
    );
  }
}
