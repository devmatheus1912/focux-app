part of 'perfil_screen.dart';

class _PerfilBody extends StatefulWidget {
  final PerfilPersonal perfil;
  final DashboardData dashboard;
  final bool uploadingPhoto;
  final bool showMfa;
  final String? freshnessLabel;
  final Future<void> Function() onRefresh;
  final VoidCallback onPickPhoto;
  final VoidCallback onEditPerfil;
  final Future<void> Function() onLogout;
  final VoidCallback onOpenLandingEditor;

  const _PerfilBody({
    required this.perfil,
    required this.dashboard,
    required this.uploadingPhoto,
    this.showMfa = false,
    this.freshnessLabel,
    required this.onRefresh,
    required this.onPickPhoto,
    required this.onEditPerfil,
    required this.onLogout,
    required this.onOpenLandingEditor,
  });

  @override
  State<_PerfilBody> createState() => _PerfilBodyState();
}

class _PerfilBodyState extends State<_PerfilBody> {
  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;
    final dashboard = widget.dashboard;
    final uploadingPhoto = widget.uploadingPhoto;
    final freshnessLabel = widget.freshnessLabel;
    final onRefresh = widget.onRefresh;
    final onPickPhoto = widget.onPickPhoto;
    final onEditPerfil = widget.onEditPerfil;
    final onLogout = widget.onLogout;
    final onOpenLandingEditor = widget.onOpenLandingEditor;
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
    final accent = BrandPalette.softened(primaryColor);
    final readiness = PerfilReadinessView.from(
      perfil: perfil,
      dashboard: dashboard,
    );
    final profileScore = readiness.score;
    final profileComplete = profileScore >= 100;
    final scrollBottomPad =
        profileComplete
            ? TokensStrip.s5
            : PerfilLayout.stickyOverlayReserve;

    return FxShellScaffold(
      useMesh: true,
      constrainWidth: true,
      appBar: FxShellAppBar(
        title: 'Perfil',
        subtitle: freshnessLabel,
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        FxSettingsLayout.pageInset,
                        FxSettingsLayout.pageInset,
                        0,
                      ),
                      child: Column(
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
                          const SizedBox(height: TokensStrip.s3),
                          Text(
                            perfil.nome,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: FxSettingsLayout.profileName(
                              context,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            _buildSubtitle(perfil),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FxSettingsLayout.subhead(color: mute),
                          ),
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            '$profileScore%',
                            textAlign: TextAlign.center,
                            style: FxSettingsLayout.rowMetric(color: mute),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    FxSettingsLayout.headerToGroup,
                    FxSettingsLayout.pageInset,
                    scrollBottomPad,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FxStaggerItem(
                            index: 3,
                            child: PerfilMarcaVitrineSection(
                              profileComplete: profileComplete,
                              children: [
                                _PerfilVitrineTiles(
                                  slug: perfil.slug,
                                  mute: mute,
                                  line: line,
                                  onOpenEditor: onOpenLandingEditor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: PerfilLayout.sectionGapPrimary,
                          ),
                          FxStaggerItem(
                            index: 5,
                            child: PerfilAppearanceSection(isDark: isDark),
                          ),
                          const SizedBox(
                            height: PerfilLayout.sectionGapQuiet,
                          ),
                          FxStaggerItem(
                            index: 6,
                            child: FxSettingsGroup(
                              header: 'Operação',
                              children: [
                                PerfilOperacaoSection(
                                  accent: accent,
                                  mute: mute,
                                  line: line,
                                  pixDone: readiness.isPixDone,
                                  planoLabel: perfilPlanRowValue(
                                    perfil.plano,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: PerfilLayout.sectionGapQuiet,
                          ),
                          FxStaggerItem(
                            index: 7,
                            child: PerfilContaSegurancaSection(
                              mute: mute,
                              line: line,
                              showMfa: widget.showMfa,
                              onMfaTap:
                                  () => context.push('/perfil/mfa'),
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
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (!profileComplete)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: FxStaggerItem(
                  index: 0,
                  slideOffset: 12,
                  duration: const Duration(milliseconds: 380),
                  child: PerfilStickyBar(
                    accent: accent,
                    isDark: isDark,
                    visible: true,
                    onComplete: onEditPerfil,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
