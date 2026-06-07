part of 'aluno_detail_screen.dart';

class _AlunoOperationalStatusSection extends ConsumerWidget {
  const _AlunoOperationalStatusSection({
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.aderenciaSemanal,
  });

  final Aluno aluno;
  final int alunoId;
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

  Widget _semTreinoTile({
    required Color mute,
    required int diasLimite,
    required bool heroShowsRisco,
  }) {
    final dias = aluno.diasSemTreino;
    final display = formatDiasSemTreinoDisplay(dias);
    final emphasis = switch (dias) {
      null => heroShowsRisco
          ? OperationalMetricEmphasis.alert
          : OperationalMetricEmphasis.muted,
      final d when d >= diasLimite => OperationalMetricEmphasis.alert,
      _ => OperationalMetricEmphasis.normal,
    };
    return OperationalMetricTile(
      label: 'Sem treino',
      value: display,
      hint: dias == null ? 'Sem histórico recente' : 'Dias parados',
      color:
          (dias ?? 0) >= diasLimite ? EagleTokens.warn : mute,
      isDark: isDark,
      emphasis: emphasis,
      semanticsLabel:
          dias == null
              ? 'Sem treino, sem registro'
              : 'Sem treino $dias dias',
    );
  }

  Widget _aderenciaTile({required Color aderenciaColor}) {
    final pct = aluno.aderenciaPercent;
    final emphasis =
        pct == null
            ? OperationalMetricEmphasis.muted
            : pct <= 0
            ? OperationalMetricEmphasis.alert
            : OperationalMetricEmphasis.normal;
    return OperationalMetricTile(
      label: 'Aderência',
      value:
          pct == null
              ? '—'
              : '$pct%',
      hint: 'Semana atual',
      color: aderenciaColor,
      isDark: isDark,
      emphasis: emphasis,
      semanticsLabel:
          aluno.aderenciaPercent == null
              ? 'Aderência indisponível'
              : 'Aderência ${aluno.aderenciaPercent} por cento',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = fxScreenInk(context);
    final configAsync = ref.watch(alertasConfigProvider);
    final diasLimite =
        configAsync.valueOrNull?.diasSemTreino ??
        AlunoFollowUpStore.diasSemTreinoLimite;
    final week = summarizeAderenciaWeek(parseAderenciaSemanal(aderenciaSemanal));
    final operacao = ref.watch(aluno360OperacaoProvider(alunoId));
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
    final showCheckinCta = shouldShowOperacaoCheckinCta(
      operacao: operacao,
      weekHasAnyCheckin: week.hasAnyCheckin,
    );
    final adherenceEmpty = resolveOperacaoAdherenceEmptyState(
      week: week,
      operacao: operacao,
    );
    final compactFollowUpVisible = shouldCompactFollowUpForContactPriority(
      contactPriority: operacao?.contactPriority ?? false,
    );
    final statusSubtitle = operacaoStatusSubtitle(
      aluno,
      heroShowsRisco: heroShowsRisco,
      compactFollowUpVisible: compactFollowUpVisible,
    );

    return Container(
      key: const ValueKey('aluno360_operacao_status'),
      decoration: Aluno360Layout.operacaoInsetSectionDecoration(
        context,
        primary: primary,
        isDark: isDark,
      ),
      padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              _OperacaoFocusModeToggle(
                alunoId: alunoId,
                primary: primary,
                iconOnly: true,
              ),
            ],
          ),
          if (statusSubtitle != null) ...[
            Text(
              statusSubtitle,
              style: Aluno360Layout.captionStyle(context),
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 8),
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
          if (heroShowsRisco)
            Row(
              children: [
                Expanded(child: _aderenciaTile(aderenciaColor: aderenciaColor)),
                const SizedBox(width: 8),
                Expanded(
                  child: _semTreinoTile(
                    mute: fxScreenMute(context),
                    diasLimite: diasLimite,
                    heroShowsRisco: heroShowsRisco,
                  ),
                ),
              ],
            )
          else ...[
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
                Expanded(child: _aderenciaTile(aderenciaColor: aderenciaColor)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _semTreinoTile(
                    mute: fxScreenMute(context),
                    diasLimite: diasLimite,
                    heroShowsRisco: heroShowsRisco,
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
          ],
          if (week.points.isNotEmpty) ...[
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final sparkMute = fxScreenMute(context);
                final sparkAccent =
                    week.hasAnyCheckin ? aderenciaColor : sparkMute;
                return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: sparkAccent.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sparkAccent.withValues(alpha: isDark ? 0.22 : 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aderência · últimos 7 dias',
                              style: Aluno360Layout.metaStyle(context).copyWith(
                                color: ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              week.caption,
                              style: Aluno360Layout.metaStyle(context).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (adherenceEmpty != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      label: adherenceEmpty.compactLine,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: EagleTokens.warn.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: EagleTokens.warn.withValues(
                              alpha: isDark ? 0.28 : 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 14,
                              color:
                                  isDark
                                      ? const Color(0xFFFFB77A)
                                      : EagleTokens.warn,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                adherenceEmpty.compactLine,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Aluno360Layout.captionStyle(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Check-ins dos últimos 7 dias',
                    child: AlunoOperacaoAdherenceBars(
                      points: week.points,
                      activeColor: aderenciaColor,
                      idleColor: neutralIdle,
                      emptyWeek: !week.hasAnyCheckin,
                    ),
                  ),
                  if (showCheckinCta &&
                      (adherenceEmpty?.showCheckinCta ?? true)) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed:
                            () => showAlunoCheckinMessageSheet(
                              context,
                              alunoId: alunoId,
                              alunoNome: aluno.nome,
                            ),
                        icon: Icon(
                          Icons.message_outlined,
                          size: 16,
                          color: primary,
                        ),
                        label: const Text(
                          'Pedir check-in',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(
                            color: primary.withValues(alpha: isDark ? 0.28 : 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
              },
            ),
          ],
        ],
      ),
    );
  }
}
