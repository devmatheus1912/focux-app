part of 'perfil_screen.dart';

class _PerfilBody extends StatelessWidget {
  final PerfilPersonal perfil;
  final DashboardData dashboard;
  final bool uploadingPhoto;
  final bool loadingMetrics;
  final String? freshnessLabel;
  final Future<void> Function() onRefresh;
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
    this.freshnessLabel,
    required this.onRefresh,
    required this.onPickPhoto,
    required this.onEditPerfil,
    required this.onLogout,
    required this.onOpenLandingEditor,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
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
    // Sticky Meus alunos / Hoje — CTA de gap fica só na prontidão (topo).
    // IA só no dock do shell (paridade Home).
    const scrollBottomPad = 108.0;
    const chromeSize = 36.0;
    const chromeGap = 3.0;

    return FxShellScaffold(
      useMesh: true,
      safeArea: false,
      constrainWidth: true,
      bottomNavigationBar: FxStaggerItem(
        index: 0,
        slideOffset: 16,
        duration: const Duration(milliseconds: 420),
        child: PerfilStickyBar(
          accent: accent,
          actionInk: actionInk,
          isDark: isDark,
          profileComplete: profileComplete,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: accent,
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: FxStaggerItem(
                  index: 1,
                  slideOffset: 18,
                  duration: const Duration(milliseconds: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s4,
                          TokensStrip.s4,
                          0,
                        ),
                        child: Row(
                          children: [
                            _HeroAction(
                              icon: Icons.arrow_back_ios_new,
                              semanticsLabel: 'Voltar',
                              size: chromeSize,
                              onTap:
                                  () => safePopOrGo(
                                    context,
                                    '/dashboard/personal',
                                  ),
                            ),
                            Expanded(
                              child: Semantics(
                                header: true,
                                label:
                                    freshnessLabel == null
                                        ? 'Perfil'
                                        : 'Perfil. $freshnessLabel',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Perfil',
                                      textAlign: TextAlign.center,
                                      style: FocuxHubTypography.pageTitle(
                                        context,
                                        color: ink,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.12,
                                      ),
                                    ),
                                    if (freshnessLabel != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        freshnessLabel!,
                                        textAlign: TextAlign.center,
                                        style: FocuxHubTypography.bodyMuted(
                                          color: mute,
                                        ).copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const ShellThemeToggle(size: chromeSize),
                            const SizedBox(width: chromeGap),
                            _HeroAction(
                              icon: Icons.edit_outlined,
                              semanticsLabel: 'Editar perfil',
                              size: chromeSize,
                              onTap: onEditPerfil,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s3,
                          TokensStrip.s4,
                          0,
                        ),
                        child: DecoratedBox(
                          decoration: fxStripCardDecoration(
                            context,
                            accent: accent,
                            radius: TokensStrip.rCard,
                            glowStrength: 0.04,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _Avatar(
                                  nome: perfil.nome,
                                  logoUrl:
                                      perfil.logoUrl ?? dashboard.logoUrl,
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _PlanPill(
                                            label: perfilPlanPillLabel(
                                              perfil.plano,
                                            ),
                                            accent: accent,
                                          ),
                                          const Spacer(),
                                          _HeroMarcaChip(
                                            score: profileScore,
                                            accent: accent,
                                            actionInk: actionInk,
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              if (!profileComplete) {
                                                // Prontidão está logo abaixo.
                                                return;
                                              }
                                              context.push(
                                                '/identidade-visual',
                                              );
                                            },
                                            onShowHint: () {
                                              HapticFeedback.selectionClick();
                                              unawaited(
                                                AnalyticsService.instance.track(
                                                  ProductEvents
                                                      .perfilMarcaHintOpened,
                                                  props: {
                                                    'score': profileScore,
                                                  },
                                                ),
                                              );
                                              FeedbackHelper.showInfo(
                                                context,
                                                'Marca $profileScore% — foto, CREF, especialidade, bio, Instagram, paleta e PIX.',
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        perfil.nome,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FocuxHubTypography.pageTitle(
                                          context,
                                          color: ink,
                                        ).copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.12,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _buildSubtitle(perfil),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FocuxHubTypography.bodyMuted(
                                          color: mute,
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
                                            style: TokensStrip.bodyMuted(
                                              color: mute,
                                            ).copyWith(
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
                        ),
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
                          FxStaggerItem(
                            index: 2,
                            child: _CompletenessCard(
                              score: profileScore,
                              accent: accent,
                              isDark: isDark,
                              items: readiness.items,
                              nextStep: readiness.nextStep,
                              onChecklistAction: onChecklistAction,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                        ],
                        FxStaggerItem(
                          index: 3,
                          child: PerfilMarcaVitrineSection(
                            profileComplete: profileComplete,
                            isDark: isDark,
                            accent: accent,
                            actionInk: actionInk,
                            brandPreview:
                                profileComplete
                                    ? null
                                    : Material(
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
                                              perfil.logoUrl ??
                                              dashboard.logoUrl,
                                          isDark: isDark,
                                          compact: true,
                                        ),
                                      ),
                                    ),
                            brandPalette:
                                profileComplete
                                    ? null
                                    : _BrandPaletteStrip(
                                      primary: primaryColor,
                                      secondary: secondaryColor,
                                      mute: mute,
                                      usingDefault: usingDefaultBrand,
                                    ),
                            publicLink: _PerfilPublicLinkCard(
                              slug: perfil.slug,
                              accent: accent,
                              actionInk: actionInk,
                              mute: mute,
                              isDark: isDark,
                              onOpenEditor: () {
                                HapticFeedback.selectionClick();
                                onOpenLandingEditor();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxStaggerItem(
                          index: 4,
                          child: _ProfessionalDataPanel(
                            summary: professionalSummary,
                            accent: accent,
                            actionInk: actionInk,
                            mute: mute,
                            isDark: isDark,
                            profileComplete: profileComplete,
                            onEdit: onEditPerfil,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxStaggerItem(
                          index: 5,
                          child: PerfilOperacaoSection(
                            isDark: isDark,
                            accent: accent,
                            actionInk: actionInk,
                            mute: mute,
                            line: line,
                            pixDone: readiness.isPixDone,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxStaggerItem(
                          index: 6,
                          child: PerfilContaSegurancaSection(
                            isDark: isDark,
                            accent: accent,
                            actionInk: actionInk,
                            mute: mute,
                            line: line,
                            onLogout: () {
                              onLogout();
                            },
                            onDeleteAccount:
                                () => _showDeleteAccountDialog(
                                  context,
                                  onSessionCleared: onLogout,
                                ),
                          ),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: TokensStrip.s3),
                          FxStaggerItem(
                            index: 7,
                            child: _PerfilDebugTools(
                              accent: accent,
                              actionInk: actionInk,
                              mute: mute,
                              line: line,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
