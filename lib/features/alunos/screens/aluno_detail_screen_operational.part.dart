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
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    OperationalMetricTile(
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
                    if (sparklineData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 8),
                        child: Semantics(
                          label: 'Tendência de aderência nos últimos 7 dias',
                          child: FxSparkline(
                            data: sparklineData,
                            color: aderenciaColor,
                            width: 52,
                            height: 20,
                            strokeWidth: 1.6,
                          ),
                        ),
                      ),
                  ],
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
        ],
      ),
    );
  }
}
