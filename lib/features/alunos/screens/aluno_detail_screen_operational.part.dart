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

  Color _dominantColor(
    OperacaoDominantMetric metric,
    Color aderenciaColor,
    Color riscoColor,
  ) {
    return switch (metric.kind) {
      OperacaoDominantMetricKind.risco => riscoColor,
      OperacaoDominantMetricKind.aderencia => aderenciaColor,
      OperacaoDominantMetricKind.prontidao => primary,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final configAsync = ref.watch(alertasConfigProvider);
    final diasLimite =
        configAsync.valueOrNull?.diasSemTreino ??
        AlunoFollowUpStore.diasSemTreinoLimite;
    final week = summarizeAderenciaWeek(parseAderenciaSemanal(aderenciaSemanal));
    final heroShowsRisco = operacaoHeroShowsRisco(aluno);
    final dominant = resolveOperacaoDominantMetric(aluno);
    final aderenciaColor = EagleTokens.aderenciaColor(
      (aluno.aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );
    final riscoColor =
        aluno.emRisco
            ? (isDark ? const Color(0xFFFFB77A) : EagleTokens.warn)
            : (isDark ? const Color(0xFF6FE296) : EagleTokens.good);
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
            heroShowsRisco
                ? 'Próximo contato: ${formatProximoContato(aluno)} · risco no hero'
                : 'Próximo contato: ${formatProximoContato(aluno)}',
            style: Aluno360Layout.captionStyle(context),
          ),
          const SizedBox(height: 12),
          if (!heroShowsRisco) ...[
          OperationalMetricTile(
            label: dominant.label,
            value: dominant.value,
            hint: dominant.hint,
            color: _dominantColor(dominant, aderenciaColor, riscoColor),
            isDark: isDark,
            leadingIcon:
                dominant.kind == OperacaoDominantMetricKind.risco
                    ? riscoMetricIcon(dominant.riscoNivel)
                    : null,
            semanticsLabel: dominant.semanticsLabel,
          ),
          const SizedBox(height: 8),
          ],
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
              if (!heroShowsRisco) ...[
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
            ],
          ),
          if (week.points.isNotEmpty) ...[
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
                        week.caption,
                        style: Aluno360Layout.metaStyle(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Check-ins dos últimos 7 dias',
                    child: AlunoOperacaoAdherenceBars(
                      points: week.points,
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
