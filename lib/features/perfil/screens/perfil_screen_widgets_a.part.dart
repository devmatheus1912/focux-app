part of 'perfil_screen.dart';

class _PerfilLoadingScaffold extends StatelessWidget {
  const _PerfilLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? EagleTokens.darkCard : TokensStrip.cardBg;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            children: [
              Container(
                height: 286,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1AABA4), Color(0xFF0A1F24)],
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
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
  final VoidCallback onLogout;
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
      final slogan = (perfil.slogan ?? '').trim();
      if (slogan.isNotEmpty) return slogan;
      final slug = perfil.slug?.trim();
      if (slug != null && slug.isNotEmpty) {
        return Env.landingPageDisplayLabel(slug);
      }
      return 'Marca ativa no app';
    }();
    final bioText =
        (perfil.descricaoProfissional ?? dashboard.descricaoProfissional ?? '')
            .trim();

    final stats = [
      _ProfileStat(
        label: 'Alunos',
        value: loadingMetrics ? '--' : dashboard.totalAlunos.toString(),
        icon: Icons.groups_2_outlined,
      ),
      _ProfileStat(
        label: 'Ativos',
        value: loadingMetrics ? '--' : dashboard.alunosAtivos.toString(),
        icon: Icons.bolt_outlined,
      ),
      _ProfileStat(label: 'Marca', value: '$profileScore%', icon: Icons.tune),
    ];

    final primaryCta =
        readiness.nextStep ??
        const PerfilNextStep(
          label: 'Operação',
          buttonLabel: 'Convidar alunos',
          action: PerfilChecklistAction.convites,
        );
    final profileComplete = profileScore >= 100;
    final usingDefaultBrand = _usesDefaultPalette(primaryColor, secondaryColor);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar:
          profileComplete
              ? _PerfilStickyBar(
                accent: accent,
                actionInk: actionInk,
                isDark: isDark,
              )
              : null,
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
                        color: heroPrimary.withValues(alpha: isDark ? 0.22 : 0.24),
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
                                          () => ref
                                              .read(themeModeProvider.notifier)
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
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _Avatar(
                                  nome: perfil.nome,
                                  logoUrl: perfil.logoUrl ?? dashboard.logoUrl,
                                  primaryColor: primaryColor,
                                  onTap: onPickPhoto,
                                  loading: uploadingPhoto,
                                  semanticsLabel:
                                      uploadingPhoto
                                          ? 'Enviando foto do perfil'
                                          : 'Alterar foto do perfil',
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PlanPill(
                                        label: perfilPlanPillLabel(perfil.plano),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        perfil.nome,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              height: 0.98,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _buildSubtitle(perfil),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _HeroQuickActions(
                              onBrand: () => context.push('/identidade-visual'),
                              onEdit: onEditPerfil,
                              onWallet: () => context.push('/perfil/wallet'),
                              onCopilot:
                                  () => goPersonalShellTab(
                                    context,
                                    '/ia/copiloto',
                                  ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.16),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(28),
                                bottomRight: Radius.circular(28),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            child: Row(
                              children: List.generate(stats.length, (index) {
                                final item = stats[index];
                                return Expanded(
                                  child: Semantics(
                                    label: '${item.label}: ${item.value}',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border:
                                            index < stats.length - 1
                                                ? Border(
                                                  right: BorderSide(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.10),
                                                  ),
                                                )
                                                : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            item.icon,
                                            size: 15,
                                            color: Colors.white.withValues(
                                              alpha: 0.78,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.value,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, profileComplete ? 28 : 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _CardSection(
                      title: 'Identidade visual',
                      subtitle:
                          'Logo, slogan e paleta aplicados no app e na experiência do aluno.',
                      trailingLabel: 'Abrir',
                      onTrailingTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/identidade-visual');
                      },
                      isDark: isDark,
                      accent: accent,
                      actionInk: actionInk,
                      child: Semantics(
                        button: true,
                        label: 'Abrir identidade visual da marca',
                        child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.push('/identidade-visual');
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BrandPreview(
                                primary: heroPrimary,
                                secondary: heroSecondary,
                                profileName: perfil.nome,
                                subtitle: brandSubtitle,
                                logoUrl: perfil.logoUrl ?? dashboard.logoUrl,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),
                              _BrandPaletteStrip(
                                primary: primaryColor,
                                secondary: secondaryColor,
                                mute: mute,
                                usingDefault: usingDefaultBrand,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    onOpenLandingEditor();
                                  },
                                  icon: const Icon(Icons.language_outlined),
                                  label: Text(
                                    perfil.slug != null
                                        ? 'Editor landing · ${Env.landingPageDisplayLabel(perfil.slug!)}'
                                        : 'Editor da landing pública',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CompletenessCard(
                      score: profileScore,
                      accent: accent,
                      isDark: isDark,
                      items: readiness.items,
                      nextStep: readiness.nextStep,
                      onChecklistAction: onChecklistAction,
                    ),
                    const SizedBox(height: 14),
                    _ProfessionalDataPanel(
                      perfil: perfil,
                      dashboard: dashboard,
                      bioText: bioText,
                      accent: accent,
                      actionInk: actionInk,
                      mute: mute,
                      line: line,
                      isDark: isDark,
                      onEdit: onEditPerfil,
                    ),
                    const SizedBox(height: 14),
                    _CardSection(
                      title: 'Operação',
                      subtitle: 'IA, alunos, carteira e ferramentas de crescimento.',
                      isDark: isDark,
                      accent: accent,
                      actionInk: actionInk,
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.auto_awesome_outlined,
                            label: 'Copiloto IA',
                            value: perfilPlanSectionLabel(perfil.plano),
                            accent: accent,
                            actionInk: actionInk,
                            mute: mute,
                            line: line,
                            onTap:
                                () => goPersonalShellTab(context, '/ia/copiloto'),
                          ),
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
                            icon: Icons.groups_2_outlined,
                            label: 'Meus alunos',
                            value:
                                loadingMetrics
                                    ? '--'
                                    : '${dashboard.totalAlunos} cadastrados',
                            accent: accent,
                            actionInk: actionInk,
                            mute: mute,
                            line: line,
                            onTap: () => goPersonalShellTab(context, '/alunos'),
                          ),
                          _ActionTile(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Carteira e PIX',
                            value:
                                _hasWallet(perfil) ? 'Completa' : 'Configurar',
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
                                  upgradeTierLabel: upgradeTierLabel,
                                  onTap: onTap,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CardSection(
                      title: 'Conta e segurança',
                      subtitle: 'Documentos legais, sessão e exclusão LGPD.',
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
                          if (kDebugMode) ...[
                            _ActionTile(
                              icon: Icons.palette_outlined,
                              label: 'TOKENS STRIP (design system)',
                              value: 'Só em debug',
                              accent: accent,
                              mute: mute,
                              line: line,
                              onTap: () => context.go('/qa/tokens-strip'),
                            ),
                            _ActionTile(
                              icon: Icons.science_outlined,
                              label: 'QA Smoke Test',
                              value: 'Só em debug',
                              accent: accent,
                              mute: mute,
                              line: line,
                              onTap: () => context.go('/qa/smoke'),
                            ),
                          ],
                          _ActionTile(
                            icon: Icons.logout,
                            label: 'Sair da conta',
                            value: '',
                            accent: EagleTokens.bad,
                            mute: mute,
                            line: line,
                            danger: true,
                            onTap: onLogout,
                          ),
                          _ActionTile(
                            icon: Icons.delete_forever_outlined,
                            label: 'Excluir minha conta',
                            value: '',
                            accent: EagleTokens.bad,
                            mute: mute,
                            line: line,
                            danger: true,
                            showDivider: false,
                            onTap: () => _showDeleteAccountDialog(context),
                          ),
                        ],
                      ),
                    ),
                    if (!profileComplete) ...[
                      const SizedBox(height: TokensStrip.s4),
                      _PerfilBottomActions(
                        profileComplete: profileComplete,
                        walletComplete: _hasWallet(perfil),
                        primaryCta: primaryCta,
                        onChecklistAction: onChecklistAction,
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

