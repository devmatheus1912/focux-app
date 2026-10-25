part of 'personal_dashboard_screen.dart';

class _PersonalDashboardScreenState
    extends ConsumerState<PersonalDashboardScreen> {
  DateTime? _homeFetchedAt;
  bool _homeViewTracked = false;
  bool _homeTtvTracked = false;
  final DateTime _homeOpenedAt = DateTime.now();
  bool _deepLinkApplied = false;
  bool _trialOfferChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboardingWizard();
    });
  }

  void _maybeOfferTrial(int totalAlunos) {
    if (_trialOfferChecked) return;
    final perfil = ref.read(perfilProvider).value;
    if (perfil == null) return;
    _trialOfferChecked = true;
    unawaited(_abrirOfertaSeCouber(perfil, totalAlunos));
  }

  Future<void> _abrirOfertaSeCouber(PerfilPersonal perfil, int alunos) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('promo_shown_${perfil.id}') ?? false;
    var treinos = 0;
    final free = perfil.plano.trim().toUpperCase() == 'FREE';
    if (!shown && !(perfil.trialUsed ?? false) && free && alunos <= 0) {
      try {
        final biblioteca = await ref
            .read(treinoRepositoryProvider)
            .getHome(size: 1);
        treinos = biblioteca.totalElements;
      } catch (_) {}
    }
    if (!mounted) return;
    if (!deveOferecerTestePro(
      promoShown: shown,
      trialUsed: perfil.trialUsed ?? false,
      plano: perfil.plano,
      alunos: alunos,
      treinos: treinos,
    )) {
      return;
    }
    context.push('/promo-pro');
  }

  /// `?sheet=search|help` abre a busca ou a ajuda; `?sheet=catalog` abre as Ferramentas.
  void _applyHomeDeepLinkOnce(BuildContext context) {
    if (_deepLinkApplied) return;
    _deepLinkApplied = true;
    final Map<String, String> params;
    try {
      params = GoRouterState.of(context).uri.queryParameters;
    } catch (_) {
      return;
    }
    final sheet = params['sheet']?.toLowerCase();
    if (sheet == null || sheet.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final primary = Theme.of(context).colorScheme.primary;
      if (sheet == 'search') {
        showDashboardQuickSearchSheet(
          context,
          isDark: isDark,
          primary: primary,
        );
        return;
      }
      if (sheet == 'help') {
        showDashboardHomeHelpSheet(context);
        return;
      }
      if (sheet == 'catalog') {
        context.push('/ferramentas');
      }
    });
  }

  Future<void> _maybeShowOnboardingWizard() async {
    try {
      final repo = OnboardingRepository(ref.read(apiClientProvider));
      final w = await OnboardingWizardClientCache.load(repo.wizard);
      if (!mounted) return;
      if (!dashboardShouldOpenOnboardingWizard(
        wizardCompleto: w.wizardCompleto,
        progressPercent: w.progressPercent,
      )) {
        return;
      }
      context.push('/onboarding/wizard');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => buildPersonalDashboardBody(context);
}
