part of 'aluno_dashboard_screen.dart';

class _StudentToolsSection extends StatelessWidget {
  final bool isDark;

  const _StudentToolsSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final tools = [
      _StudentToolAction(
        icon: Icons.fitness_center,
        title: 'Treinos',
        subtitle: 'Check-ins e histórico',
        route: '/checkin/treinos',
        emphasis: true,
      ),
      _StudentToolAction(
        icon: Icons.track_changes_outlined,
        title: 'Hábitos',
        subtitle: 'Metas diárias',
        route: '/aluno/habitos',
      ),
      _StudentToolAction(
        icon: Icons.chat_bubble_outline,
        title: 'Personal',
        subtitle: 'Chat direto',
        route: '/chat/aluno',
      ),
      _StudentToolAction(
        icon: Icons.watch_outlined,
        title: 'Prontidao',
        subtitle: 'Wearables',
        route: '/saude',
      ),
      _StudentToolAction(
        icon: Icons.emoji_events_outlined,
        title: 'Evolucao',
        subtitle: 'Streak e badges',
        route: '/gamificacao',
      ),
      _StudentToolAction(
        icon: Icons.trending_up_rounded,
        title: 'Historico',
        subtitle: 'Medidas e treinos',
        route: '/checkin/historico',
      ),
      _StudentToolAction(
        icon: Icons.groups_outlined,
        title: 'Aulas grupo',
        subtitle: 'Inscreva-se',
        route: '/aluno/grupo-aulas',
      ),
      _StudentToolAction(
        icon: Icons.videocam_outlined,
        title: 'Form check',
        subtitle: 'Análise IA',
        route: '/aluno/form-check',
      ),
      _StudentToolAction(
        icon: Icons.autorenew,
        title: 'Assinatura',
        subtitle: 'Recorrência',
        route: '/aluno/recorrencia',
      ),
      _StudentToolAction(
        icon: Icons.smart_toy_outlined,
        title: 'IA',
        subtitle: 'Rotina guiada',
        route: '/ia/aluno',
      ),
      _StudentToolAction(
        icon: Icons.payments_outlined,
        title: 'Financeiro',
        subtitle: 'Pagamentos',
        route: '/financeiro/aluno',
      ),
      _StudentToolAction(
        icon: Icons.calendar_month_outlined,
        title: 'Agenda',
        subtitle: 'Horários',
        route: '/agenda/aluno',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ferramentas',
                      style: FocuxHubTypography.pageTitle(
                        context,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Acesso rápido ao que importa.',
                      style: TextStyle(color: mute, fontSize: 12.2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tools.length} atalhos',
                  style: TextStyle(
                    color: primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final compact = constraints.maxWidth < 270;
              final itemWidth =
                  compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final tool in tools)
                    SizedBox(
                      width: itemWidth,
                      child: _StudentToolTile(
                        action: tool,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentToolAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool emphasis;

  const _StudentToolAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.emphasis = false,
  });
}

class _StudentToolTile extends StatelessWidget {
  final _StudentToolAction action;
  final bool isDark;
  final Color primary;

  const _StudentToolTile({
    required this.action,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bg =
        action.emphasis
            ? primary.withValues(alpha: isDark ? 0.18 : 0.075)
            : isDark
            ? EagleTokens.darkBg
            : EagleTokens.paperSubtle;
    final border =
        action.emphasis
            ? primary.withValues(alpha: 0.16)
            : isDark
            ? EagleTokens.darkLine
            : TokensStrip.borderDefault;

    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: BrandPalette.soft(primary, dark: isDark),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mute, fontSize: 10.7, height: 1.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlunoProfileCard extends StatelessWidget {
  final Aluno aluno;
  final bool isDark;

  const _AlunoProfileCard({required this.aluno, required this.isDark});

  String _initials(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String? _genderLabel(String? genero) {
    if (genero == null) return null;
    switch (genero.toUpperCase()) {
      case 'M':
      case 'MASCULINO':
        return 'Masculino';
      case 'F':
      case 'FEMININO':
        return 'Feminino';
      default:
        return genero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final muteColor =
        isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    final hasFoto = aluno.fotoUrl != null && aluno.fotoUrl!.isNotEmpty;
    final genderLabel = _genderLabel(aluno.genero);
    final telefone = aluno.telefone ?? aluno.whatsapp;

    return Container(
      decoration: fxListCardDecoration(context, accent: primary),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2.5),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: BrandPalette.soft(primary, dark: false),
                backgroundImage: hasFoto ? NetworkImage(aluno.fotoUrl!) : null,
                child:
                    hasFoto
                        ? null
                        : Text(
                          _initials(aluno.nome),
                          style: FocuxHubTypography.metric(
                            color: primary,
                            fontSize: FocuxHubTypography.metricEm,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno.nome,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (aluno.objetivo != null && aluno.objetivo!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      aluno.objetivo!,
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (genderLabel != null)
                        _Chip(label: genderLabel, isDark: isDark),
                      if (aluno.idade != null)
                        _Chip(
                          label: '${aluno.idade} anos',
                          icon: Icons.cake_outlined,
                          isDark: isDark,
                        ),
                      if (telefone != null && telefone.isNotEmpty)
                        _Chip(
                          label: telefone,
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                      if (aluno.tipoConsultoria != null &&
                          aluno.tipoConsultoria!.isNotEmpty)
                        _Chip(label: aluno.tipoConsultoria!, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),
            // Status dot
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: aluno.status == 'ATIVO' ? EagleTokens.good : muteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isDark;

  const _Chip({required this.label, this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fg = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
