part of 'aluno_detail_screen.dart';

class _AlunoDetailOperacaoTab extends ConsumerWidget {
  const _AlunoDetailOperacaoTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.aderenciaSemanal,
    required this.recoveryAsync,
    required this.autonomiaResumoAsync,
    required this.animateEntrance,
    required this.onEntrancePlayed,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final List<Map<String, dynamic>>? aderenciaSemanal;
  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final AsyncValue<AlunoAutonomiaResumo> autonomiaResumoAsync;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeRisk =
        aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente;
    final operacaoSnapshot = ref.watch(aluno360OperacaoProvider(alunoId));
    final contactPriority = operacaoSnapshot?.contactPriority ?? false;
    final showRecovery = alunoTemHistoricoWearable(recoveryAsync.valueOrNull);

    return Aluno360OperacaoTab(
      alunoId: alunoId,
      showFinanceRisk: financeRisk,
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      financeRiskBanner:
          financeRisk
              ? Aluno360FinanceRiskBanner(alunoId: alunoId, isDark: isDark)
              : null,
      followUpCard: Aluno360FollowUpCard(
        aluno: aluno,
        isDark: isDark,
        compactContactPriority: shouldCompactFollowUpForContactPriority(
          contactPriority: contactPriority,
        ),
      ),
      operationalSection: Aluno360OperationalStatusSection(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        primary: primary,
        aderenciaSemanal: aderenciaSemanal,
      ),
      copilotCard: Aluno360CopilotCard(
        aluno: aluno,
        alunoId: alunoId,
        resumoAsync: autonomiaResumoAsync,
        proximaAcao360: proximaAcao360,
        hasOpenCopilotTask360: hasOpenCopilotTask360,
        isDark: isDark,
        showFocusToggle: ref.watch(alunoOperacaoFocusModeProvider(alunoId)),
        focusMode: ref.watch(alunoOperacaoFocusModeProvider(alunoId)),
      ),
      recoveryCard:
          showRecovery
              ? _AlunoRecoveryInsightCard(
                recoveryAsync: recoveryAsync,
                isDark: isDark,
                primary: primary,
              )
              : null,
      quickActions: _StudentQuickActions(
        aluno: aluno,
        isDark: isDark,
        primary: primary,
        onPassword: onPassword,
        onEdit: onEdit,
        onEvolve: onEvolve,
      ),
    );
  }
}

class _AlunoDetailEvolucaoTab extends StatelessWidget {
  const _AlunoDetailEvolucaoTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.ink,
    required this.evolucaoAsync,
    required this.timeline360Async,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color ink;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final AsyncValue<List<Timeline360Event>> timeline360Async;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context) {
    return Aluno360EvolucaoTab(
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      evolucaoCard: _EvolucaoInteligenteCard(
        alunoId: alunoId,
        alunoNome: aluno.nome,
        evolucaoAsync: evolucaoAsync,
        isDark: isDark,
      ),
      timelineCard: Aluno360TimelineCard(
        aluno: aluno,
        timelineApiAsync: timeline360Async,
        isDark: isDark,
      ),
      weightCard: _AlunoWeightActivityCard(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        ink: ink,
      ),
    );
  }
}

class _AlunoDetailFerramentasTab extends ConsumerWidget {
  const _AlunoDetailFerramentasTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.perfilCompletion,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final int perfilCompletion;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final altura = formatAlturaDisplay(aluno.altura);
    final medidasAsync = ref.watch(alunoMedidasResumoProvider(alunoId));
    final medidas = medidasAsync.valueOrNull;
    final bf =
        medidas?.percGordura != null
            ? medidas!.percGordura!.toStringAsFixed(1)
            : null;
    final massaMagra =
        medidas?.massaMuscular != null
            ? medidas!.massaMuscular!.toStringAsFixed(1)
            : null;
    final evolucaoRoute = '/alunos/$alunoId/evolucao';

    return Aluno360FerramentasTab(
      primary: primary,
      isDark: isDark,
      measurementsSection: medidasAsync.when(
          loading:
              () => FxLoading.sectionShimmer(context, height: 88, showHeader: false),
          error:
              (_, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EagleTokens.bad.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  'Medidas indisponíveis agora. Tente novamente em instantes.',
                  style: TextStyle(
                    color: fxScreenMute(context),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
          data:
              (_) => LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 360 ? 2 : 4;
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final aspectBase = crossAxisCount == 2 ? 1.45 : 1.1;
                  final childAspectRatio =
                      aspectBase / textScale.clamp(1.0, 2.2);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: childAspectRatio,
                    children: [
                      Aluno360MeasurementCard(
                        label: 'Idade',
                        value: (aluno.idade ?? '—').toString(),
                        unit: 'anos',
                        isDark: isDark,
                      ),
                      Aluno360MeasurementCard(
                        label: 'Altura',
                        value: altura.value,
                        unit: altura.unit,
                        isDark: isDark,
                      ),
                      Aluno360MeasurementCard(
                        label: 'BF',
                        value: bf ?? '—',
                        unit: '%',
                        isDark: isDark,
                        emptyHint: bf == null ? 'Registrar' : null,
                        onTap:
                            bf == null
                                ? () => context.push(evolucaoRoute, extra: aluno.nome)
                                : null,
                      ),
                      Aluno360MeasurementCard(
                        label: 'M. Magra',
                        value: massaMagra ?? '—',
                        unit: 'kg',
                        isDark: isDark,
                        emptyHint: massaMagra == null ? 'Registrar' : null,
                        onTap:
                            massaMagra == null
                                ? () => context.push(evolucaoRoute, extra: aluno.nome)
                                : null,
                      ),
                    ],
                  );
                },
              ),
        ),
      modulesSection: Aluno360FerramentasModulesGrid(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        perfilCompletion: perfilCompletion,
        bf: bf,
        massaMagra: massaMagra,
      ),
    );
  }
}
