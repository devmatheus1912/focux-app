part of 'perfil_screen.dart';

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
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
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
    // Sticky Meus alunos / Copiloto — CTA de gap fica só na prontidão (topo).
    const scrollBottomPad = 108.0;

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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FxStaggerItem(
                index: 1,
                slideOffset: 18,
                duration: const Duration(milliseconds: 480),
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
                              ? [
                                TokensStrip.primaryHover,
                                EagleTokens.brandDeep,
                              ]
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
                                    style: FocuxHubTypography.eyebrow(
                                      context,
                                      color: Colors.white,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              context.push(
                                                '/identidade-visual',
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
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _buildSubtitle(perfil),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FocuxHubTypography.bodyMuted(
                                          color: Colors.white.withValues(
                                            alpha: 0.86,
                                          ),
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
                                              color: Colors.white.withValues(
                                                alpha: 0.78,
                                              ),
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
                        ],
                      ),
                    ],
                  ),
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
                          onEditBrand: () {
                            HapticFeedback.selectionClick();
                            context.push('/identidade-visual');
                          },
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
                                            perfil.logoUrl ?? dashboard.logoUrl,
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
                            compact: true,
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
                          debugTools:
                              kDebugMode
                                  ? _PerfilDebugTools(
                                    accent: accent,
                                    actionInk: actionInk,
                                    mute: mute,
                                    line: line,
                                  )
                                  : null,
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
