part of 'personal_dashboard_screen.dart';

class _PersonalDashboardScreenState
    extends ConsumerState<PersonalDashboardScreen>
    with TickerProviderStateMixin {
  FinanceiroDashboard? _finData;
  double _homeScrollOffset = 0;
  late final ScrollController _homeScrollController;
  final GlobalKey _commandPanelKey = GlobalKey();
  final GlobalKey _toolsSectionKey = GlobalKey();
  bool _prioritiesPanelOffscreen = false;
  bool _toolsBlocksSticky = false;
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

  late AnimationController _entryCtrl;
  late Animation<double> _kpiFade;
  late Animation<double> _commandFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
        showDashboardHomeHelpSheet(context);
        return;
      }
      if (sheet == 'catalog') {
        showDashboardToolsCatalogSheet(
          context,
          ref: ref,
          isDark: isDark,
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
      _entryCtrl.value = 1.0;
    } else {
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
    _measureStickyVisibility();
  }

  /// Painel off-screen + tools na faixa do chip → liga/desliga sticky.
  void _measureStickyVisibility() {
    final panelBox =
        _commandPanelKey.currentContext?.findRenderObject() as RenderBox?;
    var panelOffscreen = _prioritiesPanelOffscreen;
    if (panelBox != null && panelBox.attached && panelBox.hasSize) {
      final panelBottom =
          panelBox.localToGlobal(Offset.zero).dy + panelBox.size.height;
      final headerReserve = MediaQuery.of(context).padding.top + 48;
      panelOffscreen = dashboardPanelIsOffscreen(
        panelBottom: panelBottom,
        headerReserve: headerReserve,
        currentlyOffscreen: _prioritiesPanelOffscreen,
      );
    }

    var toolsBlocked = _toolsBlocksSticky;
    final toolsBox =
        _toolsSectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (toolsBox != null && toolsBox.attached && toolsBox.hasSize) {
      final media = MediaQuery.of(context);
      final toolsTop = toolsBox.localToGlobal(Offset.zero).dy;
      final stickyBand =
          DashboardLayout.prioritiesOverlayReserve +
          DashboardLayout.bottomDockClearance +
          media.padding.bottom +
          56;
      toolsBlocked = dashboardToolsBlocksSticky(
        toolsTopGlobal: toolsTop,
        viewportHeight: media.size.height,
        stickyBandFromBottom: stickyBand,
        currentlyBlocked: _toolsBlocksSticky,
      );
    } else {
      toolsBlocked = false;
    }

    if (dashboardScrollVisualStateChanged(
      previousPanelOffscreen: _prioritiesPanelOffscreen,
      newPanelOffscreen: panelOffscreen,
      previousToolsBlocked: _toolsBlocksSticky,
      newToolsBlocked: toolsBlocked,
    )) {
      setState(() {
        _prioritiesPanelOffscreen = panelOffscreen;
        _toolsBlocksSticky = toolsBlocked;
      });
    }
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
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFinFromHome() async {
    try {
      final home = await ref.read(dashboardHomeProvider.future);
      if (!mounted) return;
      _applyFinanceData(home.financeiro);
    } catch (e) {
      if (!mounted) return;
      // Gate de plano ≠ outage — Home já mostra locked/upsell; sem snackbar.
      if (isPlanGateError(e)) return;
      FeedbackHelper.showWarn(context, friendlyError(e));
    }
  }

  void _applyFinanceData(FinanceiroDashboard data) {
    if (!mounted) return;
    setState(() {
      _finData = data;
    });
  }

  @override
  Widget build(BuildContext context) => buildPersonalDashboardBody(context);
}
