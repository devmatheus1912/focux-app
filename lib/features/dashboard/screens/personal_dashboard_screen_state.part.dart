part of 'personal_dashboard_screen.dart';

class _PersonalDashboardScreenState
    extends ConsumerState<PersonalDashboardScreen>
    with TickerProviderStateMixin {
  FinanceiroDashboard? _finData;
  double _homeScrollOffset = 0;
  late final ScrollController _homeScrollController;
  final GlobalKey _commandPanelKey = GlobalKey();
  bool _prioritiesPanelOffscreen = false;
  int _attentionSectionResetToken = 0;
  String? _lastTrackedLocation;
  VoidCallback? _routeListener;
  RouteInformationProvider? _routeInformationProvider;
  bool _motionConfigured = false;
  bool? _persistedFocusMode;
  bool _focusMode = true;
  bool _focusPreferenceLoaded = false;
  bool _autoFocusApplied = false;
  bool _sessionFocusTouched = false;
  DateTime? _homeFetchedAt;
  bool _homeViewTracked = false;
  bool _homeTtvTracked = false;
  final DateTime _homeOpenedAt = DateTime.now();
  bool _coachSeen = true;
  bool _coachLoaded = false;
  bool _deepLinkApplied = false;

  late AnimationController _gradientCtrl;
  late AnimationController _counterCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _counterAnim;
  late Animation<double> _heroFade;
  late Animation<double> _kpiFade;
  late Animation<double> _commandFade;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _counterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _counterAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _heroFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.32, 0.78, curve: Curves.easeOutCubic),
    );
    _kpiFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.48, 0.92, curve: Curves.easeOutCubic),
    );
    _commandFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.08, 0.58, curve: Curves.easeOutCubic),
    );
    _homeScrollController = ScrollController();
    _homeScrollController.addListener(_onHomeScroll);
    _loadFinFromHome();
    _loadFocusPreference();
    _loadCoachPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboardingWizard();
      _bindDashboardReturnListener();
    });
  }

  Future<void> _loadCoachPreference() async {
    final seen = await DashboardHomeCoachStore.loadSeen();
    if (!mounted) return;
    setState(() {
      _coachLoaded = true;
      _coachSeen = seen;
    });
  }

  Future<void> _dismissCoach() async {
    await DashboardHomeCoachStore.markSeen();
    AnalyticsService.instance.track(ProductEvents.homeCoachDismissed);
    if (!mounted) return;
    setState(() => _coachSeen = true);
  }

  void _applyHomeDeepLinkOnce(BuildContext context) {
    if (_deepLinkApplied) return;
    _deepLinkApplied = true;
    final Map<String, String> params;
    try {
      params = GoRouterState.of(context).uri.queryParameters;
    } catch (_) {
      return;
    }
    final focus = params['focus']?.toLowerCase();
    if (focus == 'on' || focus == '1' || focus == 'true') {
      setState(() {
        _focusMode = true;
        _sessionFocusTouched = true;
        _autoFocusApplied = true;
      });
    } else if (focus == 'off' || focus == '0' || focus == 'false') {
      setState(() {
        _focusMode = false;
        _sessionFocusTouched = true;
        _autoFocusApplied = true;
      });
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
        showDashboardHomeHelpSheet(context, isDark: isDark);
        return;
      }
      if (sheet == 'catalog') {
        showDashboardToolsCatalogSheet(
          context,
          ref: ref,
          isDark: isDark,
          shortcutAspectRatio:
              DashboardLayout.isCompact(MediaQuery.sizeOf(context).width)
                  ? 2.55
                  : 2.85,
        );
      }
    });
  }

  Future<void> _loadFocusPreference() async {
    final persisted = await DashboardHomeFocusStore.load();
    if (!mounted) return;
    setState(() {
      _focusPreferenceLoaded = true;
      // Não sobrescreve toggle feito enquanto o load estava em voo.
      _persistedFocusMode ??= persisted;
      // Persistido ON aplica já; OFF espera o dia (crise ignora OFF).
      if (persisted == true && !_sessionFocusTouched) {
        _focusMode = true;
      }
    });
  }

  Future<void> _toggleFocusMode() async {
    dashboardHapticFocusToggle();
    final next = !_focusMode;
    setState(() {
      _focusMode = next;
      _persistedFocusMode = next;
      _sessionFocusTouched = true;
      _autoFocusApplied = true;
      _attentionSectionResetToken++;
    });
    AnalyticsService.instance.track(
      ProductEvents.homeFocusToggled,
      props: {'focus_mode': next},
    );
    await DashboardHomeFocusStore.save(next);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (TokensStrip.prefersReducedMotion(context)) {
      _gradientCtrl.stop();
      _entryCtrl.value = 1.0;
    } else {
      _gradientCtrl.repeat();
      _entryCtrl.forward(from: 0);
    }
  }

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    final offset = _homeScrollController.offset;
    if (!dashboardScrollOffsetMeaningfullyChanged(_homeScrollOffset, offset)) {
      return;
    }
    _homeScrollOffset = offset;
    _measureCommandPanelOffscreen();
  }

  /// Mede se o painel de próximas ações saiu da viewport — dita quando o CTA
  /// "Ver prioridades" aparece flutuando acima do dock.
  void _measureCommandPanelOffscreen() {
    final box =
        _commandPanelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final panelBottom = box.localToGlobal(Offset.zero).dy + box.size.height;
    final headerReserve = MediaQuery.of(context).padding.top + 48;
    final offscreen = dashboardPanelIsOffscreen(
      panelBottom: panelBottom,
      headerReserve: headerReserve,
      currentlyOffscreen: _prioritiesPanelOffscreen,
    );
    if (dashboardScrollVisualStateChanged(
      previousPanelOffscreen: _prioritiesPanelOffscreen,
      newPanelOffscreen: offscreen,
    )) {
      setState(() => _prioritiesPanelOffscreen = offscreen);
    }
  }

  void _bindDashboardReturnListener() {
    if (!mounted || _routeListener != null) return;
    final GoRouter router;
    try {
      router = GoRouter.of(context);
    } catch (_) {
      return;
    }
    _lastTrackedLocation = router.routeInformationProvider.value.uri.path;
    _routeInformationProvider = router.routeInformationProvider;
    _routeListener = () {
      final path = _routeInformationProvider!.value.uri.path;
      if (_lastTrackedLocation != null &&
          path == '/dashboard/personal' &&
          _lastTrackedLocation != '/dashboard/personal') {
        setState(() => _attentionSectionResetToken++);
      }
      _lastTrackedLocation = path;
    };
    router.routeInformationProvider.addListener(_routeListener!);
  }

  Future<void> _maybeShowOnboardingWizard() async {
    try {
      final w =
          await OnboardingRepository(ref.read(apiClientProvider)).wizard();
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
  void dispose() {
    final listener = _routeListener;
    final provider = _routeInformationProvider;
    if (listener != null && provider != null) {
      provider.removeListener(listener);
    }
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    _gradientCtrl.dispose();
    _counterCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFinFromHome() async {
    try {
      final home = await ref.read(dashboardHomeProvider.future);
      if (!mounted) return;
      _applyFinanceData(home.financeiro);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showWarn(context, friendlyError(e));
      }
    }
  }

  void _applyFinanceData(FinanceiroDashboard data) {
    if (!mounted) return;
    setState(() {
      _finData = data;
    });
    _counterAnim = Tween<double>(
      begin: 0,
      end: data.receitaMes,
    ).animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    if (TokensStrip.prefersReducedMotion(context)) {
      _counterCtrl.value = 1.0;
    } else {
      _counterCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) => buildPersonalDashboardBody(context);
}
