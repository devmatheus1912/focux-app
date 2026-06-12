part of 'treinos_list_screen.dart';

class _TreinosHeader extends StatelessWidget {
  final List<Treino> treinos;
  final int? alunoId;
  final String? alunoNome;
  final bool isDark;
  final VoidCallback? onBack;

  const _TreinosHeader({
    required this.treinos,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final primary = Theme.of(context).colorScheme.primary;
    final kickerColor = BrandPalette.sectionLink(primary, dark: isDark);
    final ready = treinos.where((t) => t.exercicios.isNotEmpty).length;
    final showBack = onBack != null;
    final planLabel = treinos.length == 1 ? 'plano' : 'planos';

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 16, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack) ...[
            IconButton(
              onPressed: onBack,
              tooltip: 'Voltar',
              icon: Container(
                width: 44,
                height: 44,
                decoration: chrome.headerAction(radius: 14),
                child: Center(
                  child: FxIcon(name: 'arrow-left', size: 18, color: ink),
                ),
              ),
            ),
            SizedBox(width: TokensStrip.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alunoId == null
                      ? '$ready pronto${ready == 1 ? '' : 's'} / ${treinos.length} $planLabel'
                      : 'Treinos do aluno',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: kickerColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: TokensStrip.s1),
                Text(
                  alunoId == null
                      ? 'Treinos'
                      : alunoNome == null || alunoNome!.trim().isEmpty
                      ? 'Treinos do aluno'
                      : 'Treinos de ${alunoNome!.trim()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 28,
                    height: 1,
                    color: ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: TokensStrip.s2),
          const ShellThemeToggle(size: 36),
          SizedBox(width: TokensStrip.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${treinos.length} ${treinos.length == 1 ? 'plano' : 'planos'}',
              style: AppTypography.inter(
                color: primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreinosCommandCard extends StatelessWidget {
  final List<Treino> treinos;
  final bool isDark;
  final Color primary;
  final bool compact;
  final VoidCallback onCreate;

  const _TreinosCommandCard({
    required this.treinos,
    required this.isDark,
    required this.primary,
    required this.compact,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primaryDeep = BrandPalette.deep(
      BrandPalette.softened(primary, amount: 0.06),
    );
    final heroPrimary = BrandPalette.softened(primary, amount: 0.06);
    final totalExercises = treinos.fold<int>(
      0,
      (sum, treino) => sum + treino.exercicios.length,
    );
    final ready = treinos.where((t) => t.exercicios.isNotEmpty).length;
    final templates = treinos.where((t) => t.isTemplate).length;
    final assembling = treinos.length - ready;
    final ultraCompact = compact;
    final metricGap = compact ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.all(ultraCompact ? 13 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [heroPrimary, primaryDeep],
        ),
        borderRadius: BorderRadius.circular(ultraCompact ? 22 : 26),
        boxShadow: [
          BoxShadow(
            color: heroPrimary.withValues(alpha: isDark ? 0.08 : 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!ultraCompact) ...[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: heroTealSurface(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: heroTealInk(),
                  ),
                ),
                SizedBox(width: TokensStrip.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biblioteca sob controle',
                      style: AppTypography.inter(
                        color: heroTealInk(),
                        fontSize: ultraCompact ? 15 : 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: ultraCompact ? 2 : 3),
                    Text(
                      assembling == 0
                          ? ultraCompact
                              ? TreinosListLabels.readyPlans(treinos.length)
                              : 'Todos os planos têm exercícios.'
                          : '$assembling plano${assembling == 1 ? '' : 's'} ainda em montagem.',
                      style: AppTypography.inter(
                        color: heroTealSurface(0.74),
                        fontSize: ultraCompact ? 11.2 : 12.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: TokensStrip.s3),
              TextButton.icon(
                onPressed: onCreate,
                style: TextButton.styleFrom(
                  foregroundColor: heroTealInk(),
                  backgroundColor: heroTealSurface(0.14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(
                  'Novo',
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ultraCompact ? 9 : TokensStrip.s4),
          if (ultraCompact)
            _CommandInlineMetrics(
              ready: ready,
              totalExercises: totalExercises,
              templates: templates,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _CommandMetric(
                    label: 'prontos',
                    value: '$ready',
                    textColor: ink,
                    muteColor: mute,
                  ),
                ),
                SizedBox(width: metricGap),
                Expanded(
                  child: _CommandMetric(
                    label: 'exercícios',
                    value: '$totalExercises',
                    textColor: ink,
                    muteColor: mute,
                  ),
                ),
                SizedBox(width: metricGap),
                Expanded(
                  child: _CommandMetric(
                    label: 'templates',
                    value: '$templates',
                    textColor: ink,
                    muteColor: mute,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CommandInlineMetrics extends StatelessWidget {
  final int ready;
  final int totalExercises;
  final int templates;

  const _CommandInlineMetrics({
    required this.ready,
    required this.totalExercises,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: heroTealSurface(0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: heroTealSurface(0.10)),
      ),
      child: Text(
        '${TreinosListLabels.readyCount(ready)} · $totalExercises exercícios · ${TreinosListLabels.templateCount(templates)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.inter(
          color: heroTealSurface(0.86),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommandMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color muteColor;

  const _CommandMetric({
    required this.label,
    required this.value,
    required this.textColor,
    required this.muteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: heroTealSurface(0.14),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: heroTealSurface(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              color: heroTealInk(),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          SizedBox(height: TokensStrip.s1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              color: heroTealSurface(0.68),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.inter(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          action,
          style: AppTypography.inter(
            color: mute,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LibraryControls extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final int selectedCount;
  final bool selectionMode;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback? onSelectAll;
  final VoidCallback onCancelSelection;
  final VoidCallback? onDeleteSelected;

  const _LibraryControls({
    required this.controller,
    required this.query,
    required this.selectedCount,
    required this.selectionMode,
    required this.isDark,
    required this.primary,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSelectAll,
    required this.onCancelSelection,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : heroTealSurface(0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark
                  ? line
                  : primary.withValues(alpha: selectionMode ? 0.28 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child:
                selectionMode
                    ? Row(
                      key: const ValueKey('selection-toolbar'),
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 19,
                          ),
                        ),
                        SizedBox(width: TokensStrip.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$selectedCount selecionado${selectedCount == 1 ? '' : 's'}',
                                style: AppTypography.inter(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              Text(
                                'Ações em lote',
                                style: AppTypography.inter(
                                  color: mute,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onCancelSelection,
                          tooltip: 'Cancelar seleção',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                isDark
                                    ? EagleTokens.darkBg
                                    : heroTealSurface(0.72),
                          ),
                          icon: Icon(
                            Icons.close_rounded,
                            color: mute,
                            size: 19,
                          ),
                        ),
                        SizedBox(width: TokensStrip.s2),
                        FilledButton.icon(
                          onPressed: onDeleteSelected,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                          ),
                          label: const Text('Excluir'),
                          style: FilledButton.styleFrom(
                            backgroundColor: EagleTokens.bad,
                            foregroundColor: heroTealInk(),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    )
                    : Row(
                      key: const ValueKey('normal-toolbar'),
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: primary,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: TokensStrip.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Operações da biblioteca',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              Text(
                                query.trim().isEmpty
                                    ? 'Buscar, selecionar e organizar'
                                    : 'Filtro aplicado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  color: mute,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: TokensStrip.s2),
                        FilledButton.tonalIcon(
                          onPressed: onSelectAll,
                          icon: const Icon(Icons.checklist_rounded, size: 17),
                          label: const Text('Selecionar'),
                          style: FilledButton.styleFrom(
                            foregroundColor: primary,
                            backgroundColor:
                                isDark
                                    ? primary.withValues(alpha: 0.16)
                                    : heroTealSurface(0.86),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          SizedBox(height: TokensStrip.s3),
          Semantics(
            label: 'Buscar treino por nome, objetivo ou nível',
            textField: true,
            child: TextField(
              onChanged: onQueryChanged,
              controller: controller,
              textInputAction: TextInputAction.search,
              style: AppTypography.inter(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar treino, objetivo ou nível',
                hintStyle: AppTypography.inter(
                  color: mute,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: primary,
                  size: 20,
                ),
                suffixIcon:
                    query.trim().isEmpty
                        ? null
                        : IconButton(
                          onPressed: onClearQuery,
                          icon: Icon(
                            Icons.close_rounded,
                            color: mute,
                            size: 18,
                          ),
                        ),
                filled: true,
                fillColor: isDark ? EagleTokens.darkBg : heroTealSurface(0.92),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                enabledBorder: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? EagleTokens.darkLine : heroTealInk(),
                  ),
                ),
                focusedBorder: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: primary.withValues(alpha: 0.42),
                  ),
                ),
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
