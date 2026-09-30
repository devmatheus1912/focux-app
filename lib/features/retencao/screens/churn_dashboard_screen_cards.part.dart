part of 'churn_dashboard_screen.dart';

class _RetencaoMetricStrip extends StatelessWidget {
  const _RetencaoMetricStrip({
    required this.home,
    required this.isDark,
    required this.primary,
    required this.onFiltrarAlto,
  });

  final RetencaoHome home;
  final bool isDark;
  final Color primary;
  final VoidCallback onFiltrarAlto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: home.alto > 0 ? onFiltrarAlto : null,
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            child: OperationalMetricTile(
              label: retencaoMetricAlto,
              value: '${home.alto}',
              hint:
                  retencaoAltoVariacaoHint(
                    home.alto,
                    home.altoSemanaAnterior,
                  ) ??
                  '',
              color: EagleTokens.bad,
              isDark: isDark,
              dense: true,
              emphasis:
                  home.alto > 0
                      ? OperationalMetricEmphasis.alert
                      : OperationalMetricEmphasis.muted,
              semanticsLabel: retencaoMetricAltoLabel(home.alto),
            ),
          ),
        ),
        const SizedBox(width: TokensStrip.s2),
        Expanded(
          child: OperationalMetricTile(
            label: retencaoMetricMedio,
            value: '${home.medio}',
            color: EagleTokens.warn,
            isDark: isDark,
            dense: true,
            emphasis: OperationalMetricEmphasis.muted,
            semanticsLabel: retencaoMetricMedioLabel(home.medio),
          ),
        ),
        const SizedBox(width: TokensStrip.s2),
        Expanded(
          child: OperationalMetricTile(
            label: retencaoMetricSaudavel,
            value: '${home.saudavel}',
            color: primary,
            isDark: isDark,
            dense: true,
            emphasis: OperationalMetricEmphasis.muted,
            semanticsLabel: retencaoMetricSaudavelLabel(home.saudavel),
          ),
        ),
      ],
    );
  }
}

class _RetencaoFocusCard extends StatelessWidget {
  const _RetencaoFocusCard({
    required this.home,
    required this.isDark,
    required this.onAluno,
    required this.onChat,
    required this.onCobrar,
  });

  final RetencaoHome home;
  final bool isDark;
  final void Function(RetencaoAlunoScore score) onAluno;
  final void Function(RetencaoAlunoScore score) onChat;
  final void Function(RetencaoAlunoScore score) onCobrar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final alto = home.alto;
    final firstAlto = firstAltoRetencao(home.top3);
    final split = retencaoFocusActions(hasAlto: firstAlto != null);

    VoidCallback run(RetencaoFocusActionId id) => switch (id) {
      RetencaoFocusActionId.chat => () => onChat(firstAlto!),
      RetencaoFocusActionId.cobrar => () => onCobrar(firstAlto!),
      RetencaoFocusActionId.aluno360 => () => onAluno(firstAlto!),
      RetencaoFocusActionId.verAlunos => () {
        AnalyticsService.instance.track(ProductEvents.alunosViewed);
        goPersonalShellTab(context, '/alunos');
      },
    };

    Future<void> openMais() async {
      final chosen = await showFxInsetPickerSheet<RetencaoFocusActionId>(
        context,
        title: retencaoMaisAcoes,
        headerIcon: Icons.more_horiz_rounded,
        selected: null,
        items: [
          for (final id in split.secondary)
            FxInsetPickerSheetItem(
              value: id,
              label: retencaoFocusActionLabel(id),
            ),
        ],
      );
      if (chosen == null) return;
      HapticFeedback.selectionClick();
      run(chosen)();
    }

    final focusTitle =
        firstAlto != null
            ? firstAlto.alunoNome
            : retencaoFocusEmptyTitle(alto);

    final focusSubtitle =
        firstAlto != null
            ? retencaoPorque(firstAlto)
            : retencaoContagensSubtitulo(
              alto: home.alto,
              medio: home.medio,
              saudavel: home.saudavel,
              topNomeados: retencaoItemsForFiltro(home.top3, null).length,
            );

    return FxStripCard(
      emphasize: true,
      padding: const EdgeInsets.all(TokensStrip.s3),
      semanticsLabel:
          alto == 0
              ? retencaoNenhumRiscoAlto
              : retencaoFocusSemantics(alto),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstAlto != null ? retencaoProximoContato : retencaoRiscoChurnTitle,
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            focusTitle,
            style: FocuxHubTypography.sectionTitle(
              context,
              color: chrome.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            focusSubtitle,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TokensStrip.s2),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              FxActionChip(
                label: retencaoFocusActionLabel(split.primary),
                accent: primary,
                isDark: isDark,
                onPressed: run(split.primary),
                solid: true,
              ),
              if (split.secondary.isNotEmpty)
                FxActionChip(
                  label: retencaoMaisAcoes,
                  accent: chrome.mute,
                  isDark: isDark,
                  onPressed: openMais,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetencaoTile extends StatelessWidget {
  const _RetencaoTile({
    required this.score,
    required this.isDark,
    required this.onChat,
    required this.onAluno,
    required this.onMais,
  });

  final RetencaoAlunoScore score;
  final bool isDark;
  final VoidCallback onChat;
  final VoidCallback onAluno;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = ShellChrome.of(context).mute;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: FxSatelliteListTile(
        title: score.alunoNome,
        subtitle: Text(retencaoPorque(score)),
        // Risco = copy no subtitle; sem glow full-bleed no card.
        accent: null,
        onTap: onAluno,
        onLongPress: onMais,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: TokensStrip.s7,
              height: TokensStrip.s7,
              child: IconButton(
                tooltip: retencaoFocusActionLabel(RetencaoFocusActionId.chat),
                onPressed: onChat,
                icon: Icon(Icons.chat_bubble_outline_rounded, color: primary),
              ),
            ),
            SizedBox(
              width: TokensStrip.s7,
              height: TokensStrip.s7,
              child: IconButton(
                tooltip: retencaoMaisAcoes,
                onPressed: onMais,
                icon: Icon(Icons.more_horiz_rounded, color: mute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
