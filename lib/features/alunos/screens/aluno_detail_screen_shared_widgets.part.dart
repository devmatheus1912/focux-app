part of 'aluno_detail_screen.dart';

class _Aluno360Signal {
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _Aluno360Signal({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });
}

class _ProfileGap {
  final IconData icon;
  final String title;
  final String detail;
  final String route;

  const _ProfileGap({
    required this.icon,
    required this.title,
    required this.detail,
    required this.route,
  });
}

class _Aluno360SignalTile extends StatelessWidget {
  final _Aluno360Signal signal;

  const _Aluno360SignalTile({required this.signal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final semanticsLabel =
        '${signal.label}: ${signal.value}. ${signal.detail}';
    return Semantics(
      label: semanticsLabel,
      button: signal.detail.isNotEmpty,
      child: Tooltip(
        message: signal.detail,
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: signal.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  signal.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (signal.detail.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    signal.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mute,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }
}

class _CopilotPrescription extends StatefulWidget {
  final String title;
  final String action;
  final String reason;
  final Color color;

  const _CopilotPrescription({
    required this.title,
    required this.action,
    required this.reason,
    required this.color,
  });

  @override
  State<_CopilotPrescription> createState() => _CopilotPrescriptionState();
}

class _CopilotPrescriptionState extends State<_CopilotPrescription> {
  static const _collapsedLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final reason = widget.reason.trim();
    final showExpand = reason.length > 72;

    return Semantics(
      label:
          '${widget.title}. ${widget.action}. $reason'
          '${showExpand && !_expanded ? '. Toque para ver texto completo' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            widget.action,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.28,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 5),
            GestureDetector(
              onTap:
                  showExpand
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
              behavior: HitTestBehavior.opaque,
              child: Text(
                reason,
                maxLines: _expanded ? null : _collapsedLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: TextStyle(color: mute, fontSize: 12, height: 1.25),
              ),
            ),
            if (showExpand && !_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ver mais',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CopilotPrescriptionLoading extends StatelessWidget {
  const _CopilotPrescriptionLoading({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.12);
    final highlight =
        isDark
            ? Colors.white.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.28);

    Widget bone(double w, double h, {double radius = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Semantics(
      label: 'Carregando sugestão do Copiloto',
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bone(17, 17, radius: 4),
                const SizedBox(width: 7),
                Expanded(child: bone(double.infinity, 12, radius: 6)),
              ],
            ),
            const SizedBox(height: 10),
            bone(double.infinity, 14, radius: 6),
            const SizedBox(height: 6),
            bone(220, 14, radius: 6),
            const SizedBox(height: 8),
            bone(180, 11, radius: 6),
          ],
        ),
      ),
    );
  }
}

class _CopilotTaskStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CopilotTaskStatus({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Aluno360ActionRow extends ConsumerStatefulWidget {
  final Aluno aluno;
  final Color primary;
  final FilaAcaoResumo? existingTask;
  final bool openTaskHint;
  /// When true and a task is open, primary CTA lives in the sticky bar only.
  final bool hidePrimaryCta;
  final String acao;
  final Future<bool> Function(String acao) onAssign;
  final void Function(String acao) onPrepareMessage;

  const _Aluno360ActionRow({
    required this.aluno,
    required this.primary,
    required this.existingTask,
    this.openTaskHint = false,
    this.hidePrimaryCta = false,
    required this.acao,
    required this.onAssign,
    required this.onPrepareMessage,
  });

  @override
  ConsumerState<_Aluno360ActionRow> createState() => _Aluno360ActionRowState();
}

class _Aluno360ActionRowState extends ConsumerState<_Aluno360ActionRow> {
  bool _creating = false;
  bool _created = false;

  Future<void> _handlePrimary() async {
    if (widget.existingTask != null || widget.openTaskHint || _created) {
      context.push('/dashboard/command-center/copiloto');
      return;
    }
    ref.read(alunoCopilotCreatingProvider(widget.aluno.id).notifier).state = true;
    setState(() => _creating = true);
    final created = await widget.onAssign(widget.acao);
    if (!mounted) return;
    ref.read(alunoCopilotCreatingProvider(widget.aluno.id).notifier).state = false;
    setState(() {
      _creating = false;
      _created = created;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTask = widget.existingTask != null || widget.openTaskHint || _created;
    final hidePrimary = widget.hidePrimaryCta && hasTask;
    return Row(
      children: [
        if (!hidePrimary) ...[
          Expanded(
            flex: 3,
            child:
                hasTask
                    ? Semantics(
                      button: true,
                      label: 'Abrir Command Center',
                      child: Tooltip(
                        message: 'Abrir no Command Center',
                        child: TextButton.icon(
                          onPressed: _handlePrimary,
                          icon: Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: widget.primary,
                          ),
                          label: Text(
                            'Command Center',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    )
                    : FxLiquidPrimaryButton(
                      loading: _creating,
                      icon: Icons.task_alt_rounded,
                      label: _creating ? 'Criando...' : 'Criar tarefa',
                      onPressed: _creating ? null : _handlePrimary,
                    ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: hidePrimary ? 1 : 2,
          child: Semantics(
            button: true,
            label: 'Abrir chat com ${widget.aluno.nome}',
            child: SizedBox(
            height: 44,
            child: InkWell(
            onTap: () {
              widget.onPrepareMessage(widget.acao);
            },
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: widget.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Abrir chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          ),
        ),
      ],
    );
  }
}

class _MiniAutonomyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniAutonomyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyMiniState extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _EmptyMiniState({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mute,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Aluno360SecondaryAction {
  const _Aluno360SecondaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _Aluno360ActionEmptyPanel extends StatelessWidget {
  const _Aluno360ActionEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryActions = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final List<_Aluno360SecondaryAction> secondaryActions;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: onPrimary,
              icon: Icon(primaryIcon, size: 16),
              label: Text(primaryLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          if (secondaryActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final action in secondaryActions)
                  Semantics(
                    button: true,
                    label: action.label,
                    child: TextButton.icon(
                      onPressed: action.onTap,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: primary,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(action.icon, size: 15),
                      label: Text(
                        action.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AlunoDetailLoadingSkeleton extends StatelessWidget {
  const _AlunoDetailLoadingSkeleton({
    required this.tabController,
    required this.isDark,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.line,
    required this.sheetFill,
  });

  final TabController tabController;
  final bool isDark;
  final Color primary;
  final Color ink;
  final Color mute;
  final Color line;
  final Color sheetFill;

  @override
  Widget build(BuildContext context) {
    final heroExpandedHeight = Aluno360Layout.heroExpandedHeight(context);

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: heroExpandedHeight,
          pinned: true,
          backgroundColor: sheetFill,
          surfaceTintColor: sheetFill,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
              tooltip: 'Voltar',
              onPressed: () => safePopOrGo(context, '/alunos'),
              icon: Container(
                width: 38,
                height: 38,
                decoration: ShellChrome.of(context).headerAction(radius: 12),
                child: Icon(Icons.arrow_back_ios_new, size: 16, color: ink),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Padding(
              padding: EdgeInsets.fromLTRB(
                TokensStrip.s4,
                MediaQuery.paddingOf(context).top + kToolbarHeight + 2,
                TokensStrip.s4,
                4,
              ),
              child: Semantics(
                label: 'Carregando perfil do aluno',
                child: _AlunoDetailHeroSkeleton(isDark: isDark, primary: primary),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: null,
              icon: Icon(Icons.more_horiz_rounded, color: ink.withValues(alpha: 0.45)),
            ),
            const ShellThemeToggle(size: 38),
            const SizedBox(width: 8),
          ],
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _AlunoDetailTabBarDelegate(
            tabController: tabController,
            primary: primary,
            mute: mute,
            line: line,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Aluno360Layout.screenPadding,
              Aluno360Layout.sectionGap,
              Aluno360Layout.screenPadding,
              24,
            ),
            child: Column(
              children: [
                Semantics(
                  label: 'Carregando follow-up',
                  child: FxLoading.sectionShimmer(context, height: 168),
                ),
                const SizedBox(height: Aluno360Layout.sectionGap),
                Semantics(
                  label: 'Carregando status operacional',
                  child: FxLoading.sectionShimmer(context, height: 248),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlunoDetailHeroSkeleton extends StatelessWidget {
  const _AlunoDetailHeroSkeleton({
    required this.isDark,
    required this.primary,
  });

  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final base =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : primary.withValues(alpha: 0.12);
    final highlight =
        isDark
            ? Colors.white.withValues(alpha: 0.22)
            : primary.withValues(alpha: 0.22);

    Widget bone(double w, double h, {double radius = 12}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        key: const ValueKey('aluno360_hero_skeleton'),
        width: double.infinity,
        height: Aluno360Layout.heroBodyHeight(context),
        padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bone(52, 52, radius: 26),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: bone(120, 16, radius: 8)),
                      const SizedBox(width: 8),
                      bone(64, 22, radius: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  bone(double.infinity, 28, radius: 10),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: bone(80, 10, radius: 6)),
                      const SizedBox(width: 12),
                      bone(48, 22, radius: 8),
                    ],
                  ),
                  const SizedBox(height: 6),
                  bone(160, 10, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

