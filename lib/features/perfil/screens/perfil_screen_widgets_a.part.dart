part of 'perfil_screen.dart';

class _PerfilLoadingScaffold extends StatelessWidget {
  const _PerfilLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? EagleTokens.darkCard : TokensStrip.cardBg;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    final primary = theme.colorScheme.primary;

    return FxShellScaffold(
      useMesh: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          children: [
            Container(
              height: 286,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: [primary, BrandPalette.deep(primary)],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final height in [132.0, 178.0, 228.0])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PerfilErrorScaffold extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _PerfilErrorScaffold({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return FxShellScaffold(
      useMesh: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: EagleTokens.badSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  color: EagleTokens.bad,
                  size: 28,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              Text(
                'Perfil indisponível',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                friendlyError(
                  error,
                  fallback: 'Não foi possível carregar seus dados agora.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, height: 1.35),
              ),
              const SizedBox(height: 18),
              FxLiquidPrimaryButton(
                icon: Icons.refresh_rounded,
                label: 'Tentar novamente',
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilBody extends StatelessWidget {
  final PerfilPersonal perfil;
  final DashboardData dashboard;
  final bool uploadingPhoto;
  final bool loadingMetrics;
  final VoidCallback onPickPhoto;
  final VoidCallback onEditPerfil;
  final Future<void> Function() onLogout;
  final VoidCallback onOpenLandingEditor;
  final void Function(PerfilChecklistAction action) onChecklistAction;

  const _PerfilBody({
    required this.perfil,
    required this.dashboard,
    required this.uploadingPhoto,
    this.loadingMetrics = false,
    required this.onPickPhoto,
    required this.onEditPerfil,
    required this.onLogout,
    required this.onOpenLandingEditor,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final themePrimary = theme.colorScheme.primary;

    final primaryColor = _parseColor(
      perfil.corPrimaria ?? dashboard.corPrimaria,
      fallback: themePrimary,
    );
    final secondaryColor = _parseColor(
      perfil.corSecundaria ?? dashboard.corSecundaria,
      fallback: BrandPalette.deep(themePrimary),
    );
    final accent = BrandPalette.softened(primaryColor);
    final actionInk = isDark ? primaryColor : BrandPalette.deep(primaryColor);
    final heroPrimary = BrandPalette.softened(primaryColor, amount: 0.10);
    final heroSecondary = BrandPalette.softened(secondaryColor, amount: 0.14);
    final readiness = PerfilReadinessView.from(
      perfil: perfil,
      dashboard: dashboard,
    );
    final profileScore = readiness.score;
    final brandSubtitle = () {
      final slogan = formatBrandSloganForDisplay((perfil.slogan ?? '').trim());
      if (slogan.isNotEmpty) return slogan;
      final slug = perfil.slug?.trim();
      if (slug != null && slug.isNotEmpty) {
        return Env.landingPageDisplayLabel(slug);
      }
      return 'Marca ativa no app';
    }();
    final professionalSummary = PerfilProfessionalSummary.from(
      perfil: perfil,
      dashboard: dashboard,
    );

    final profileComplete = profileScore >= 100;
    final alunosLabel =
        loadingMetrics
            ? '—'
            : '${dashboard.totalAlunos} alunos · ${dashboard.alunosAtivos} ativos';
    final usingDefaultBrand = _usesDefaultPalette(primaryColor, secondaryColor);
    // Sticky Meus alunos / Copiloto — CTA de gap fica só na prontidão (topo).
    const scrollBottomPad = 108.0;

    return FxShellScaffold(
      useMesh: true,
      safeArea: false,
      constrainWidth: true,
      bottomNavigationBar: _PerfilStickyBar(
        accent: accent,
        actionInk: actionInk,
        isDark: isDark,
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    transform: const GradientRotation(160 * math.pi / 180),
                    colors:
                        isDark
                            ? [TokensStrip.primaryHover, EagleTokens.brandDeep]
                            : [heroPrimary, heroSecondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: heroPrimary.withValues(
                        alpha: isDark ? 0.22 : 0.24,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _ProfileTexturePainter()),
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _HeroAction(
                                icon: Icons.arrow_back_ios_new,
                                semanticsLabel: 'Voltar',
                                onTap:
                                    () => safePopOrGo(
                                      context,
                                      '/dashboard/personal',
                                    ),
                              ),
                              Semantics(
                                header: true,
                                label: 'Perfil',
                                child: Text(
                                  'Perfil',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Consumer(
                                builder: (context, ref, _) {
                                  final themeDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  return _HeroAction(
                                    icon:
                                        themeDark
                                            ? Icons.wb_sunny_outlined
                                            : Icons.dark_mode_outlined,
                                    semanticsLabel:
                                        themeDark
                                            ? 'Ativar tema claro'
                                            : 'Ativar tema escuro',
                                    onTap:
                                        () =>
                                            ref
                                                .read(
                                                  themeModeProvider.notifier,
                                                )
                                                .toggle(),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              _HeroAction(
                                icon: Icons.edit_outlined,
                                semanticsLabel: 'Editar perfil',
                                onTap: onEditPerfil,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            0,
                            TokensStrip.s4,
                            TokensStrip.s3,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _Avatar(
                                nome: perfil.nome,
                                logoUrl: perfil.logoUrl ?? dashboard.logoUrl,
                                primaryColor: primaryColor,
                                onTap: onPickPhoto,
                                loading: uploadingPhoto,
                                compact: true,
                                showEditBadge: false,
                                semanticsLabel:
                                    uploadingPhoto
                                        ? 'Enviando foto do perfil'
                                        : 'Alterar foto do perfil',
                              ),
                              const SizedBox(width: TokensStrip.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _PlanPill(
                                          label: perfilPlanPillLabel(
                                            perfil.plano,
                                          ),
                                        ),
                                        const Spacer(),
                                        _HeroMarcaChip(
                                          score: profileScore,
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            if (!profileComplete) {
                                              // Prontidão está logo abaixo.
                                              return;
                                            }
                                            context.push('/identidade-visual');
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      perfil.nome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            height: 1.05,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _buildSubtitle(perfil),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.86,
                                        ),
                                        fontSize: 12.5,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Semantics(
                                      button: true,
                                      label: '$alunosLabel. Abrir alunos',
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          goPersonalShellTab(
                                            context,
                                            '/alunos',
                                          );
                                        },
                                        child: Text(
                                          alunosLabel,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.78,
                                            ),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                TokensStrip.s4,
                TokensStrip.s3,
                TokensStrip.s4,
                scrollBottomPad,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!profileComplete) ...[
                          _CompletenessCard(
                            score: profileScore,
                            accent: accent,
                            isDark: isDark,
                            items: readiness.items,
                            nextStep: readiness.nextStep,
                            onChecklistAction: onChecklistAction,
                          ),
                          const SizedBox(height: TokensStrip.s3),
                        ],
                        _CardSection(
                          title: 'Marca e vitrine',
                          subtitle:
                              profileComplete
                                  ? 'Link e compartilhamento da vitrine.'
                                  : 'Link para divulgar e preview do aluno.',
                          trailingLabel: 'Editar',
                          onTrailingTap: () {
                            HapticFeedback.selectionClick();
                            context.push('/identidade-visual');
                          },
                          isDark: isDark,
                          accent: accent,
                          actionInk: actionInk,
                          child: Semantics(
                            container: true,
                            label: 'Marca e vitrine online',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!profileComplete) ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        context.push('/identidade-visual');
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: _BrandPreview(
                                        primary: heroPrimary,
                                        secondary: heroSecondary,
                                        profileName: perfil.nome,
                                        subtitle: brandSubtitle,
                                        logoUrl:
                                            perfil.logoUrl ?? dashboard.logoUrl,
                                        isDark: isDark,
                                        compact: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: TokensStrip.s2),
                                  _BrandPaletteStrip(
                                    primary: primaryColor,
                                    secondary: secondaryColor,
                                    mute: mute,
                                    usingDefault: usingDefaultBrand,
                                  ),
                                  const SizedBox(height: TokensStrip.s2),
                                ],
                                _PerfilPublicLinkCard(
                                  slug: perfil.slug,
                                  accent: accent,
                                  actionInk: actionInk,
                                  mute: mute,
                                  isDark: isDark,
                                  compact: true,
                                  onOpenEditor: () {
                                    HapticFeedback.selectionClick();
                                    onOpenLandingEditor();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        _ProfessionalDataPanel(
                          summary: professionalSummary,
                          accent: accent,
                          actionInk: actionInk,
                          mute: mute,
                          isDark: isDark,
                          onEdit: onEditPerfil,
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        _CardSection(
                          title: 'Operação',
                          subtitle: 'Plano, carteira e crescimento.',
                          isDark: isDark,
                          accent: accent,
                          actionInk: actionInk,
                          child: Column(
                            children: [
                              _ActionTile(
                                icon: Icons.workspace_premium_outlined,
                                label: 'Planos e assinatura',
                                value: 'Gerenciar',
                                accent: accent,
                                actionInk: actionInk,
                                mute: mute,
                                line: line,
                                onTap: () => context.push('/assinatura'),
                              ),
                              _ActionTile(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Carteira e PIX',
                                value:
                                    readiness.isPixDone
                                        ? 'Completa'
                                        : 'Configurar',
                                accent: accent,
                                actionInk: actionInk,
                                mute: mute,
                                line: line,
                                onTap: () => context.push('/perfil/wallet'),
                              ),
                              _ActionTile(
                                icon: Icons.bolt_outlined,
                                label: 'Migração Focux',
                                value: 'Importar com IA',
                                accent: accent,
                                actionInk: actionInk,
                                mute: mute,
                                line: line,
                                onTap: () => context.push('/migracao-magica'),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    childrenPadding: EdgeInsets.zero,
                                    initiallyExpanded: false,
                                    iconColor: mute,
                                    collapsedIconColor: mute,
                                    title: Text(
                                      'Mais ferramentas',
                                      style: TextStyle(
                                        color: ink,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Crescimento, loja, equipe e hábitos',
                                      style: TextStyle(
                                        color: mute,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    children: [
                                      GatedProfileShortcuts(
                                        accent: accent,
                                        actionInk: actionInk,
                                        mute: mute,
                                        line: line,
                                        tileBuilder:
                                            ({
                                              required icon,
                                              required label,
                                              required value,
                                              required onTap,
                                              required locked,
                                              upgradeTierLabel,
                                            }) => _ActionTile(
                                              icon: icon,
                                              label: label,
                                              value: value,
                                              accent: accent,
                                              actionInk: actionInk,
                                              mute: mute,
                                              line: line,
                                              locked: locked,
                                              upgradeTierLabel:
                                                  upgradeTierLabel,
                                              onTap: onTap,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        _CardSection(
                          title: 'Conta e segurança',
                          subtitle:
                              'Documentos legais, sessão e exclusão LGPD.',
                          isDark: isDark,
                          accent: accent,
                          actionInk: actionInk,
                          child: Column(
                            children: [
                              _ActionTile(
                                icon: Icons.description_outlined,
                                label: 'Termos de uso',
                                value: '',
                                accent: accent,
                                actionInk: actionInk,
                                mute: mute,
                                line: line,
                                onTap: () => FocuxLegal.openTerms(),
                              ),
                              _ActionTile(
                                icon: Icons.privacy_tip_outlined,
                                label: 'Política de privacidade',
                                value: '',
                                accent: accent,
                                actionInk: actionInk,
                                mute: mute,
                                line: line,
                                onTap: () => FocuxLegal.openPrivacy(),
                              ),
                              _ActionTile(
                                icon: Icons.logout,
                                label: 'Sair da conta',
                                value: '',
                                accent: EagleTokens.bad,
                                mute: mute,
                                line: line,
                                danger: true,
                                onTap: () {
                                  onLogout();
                                },
                              ),
                              _ActionTile(
                                icon: Icons.delete_forever_outlined,
                                label: 'Excluir minha conta',
                                value: '',
                                accent: EagleTokens.bad,
                                mute: mute,
                                line: line,
                                danger: true,
                                showDivider: kDebugMode,
                                onTap:
                                    () => _showDeleteAccountDialog(
                                      context,
                                      onSessionCleared: onLogout,
                                    ),
                              ),
                              if (kDebugMode)
                                _PerfilDebugTools(
                                  accent: accent,
                                  actionInk: actionInk,
                                  mute: mute,
                                  line: line,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
