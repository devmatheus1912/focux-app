part of 'personal_dashboard_screen.dart';

class _PersonalDashboardScreenState
    extends ConsumerState<PersonalDashboardScreen>
    with TickerProviderStateMixin {
  FinanceiroDashboard? _finData;
  bool _loadingFin = true;
  double _homeScrollOffset = 0;
  late final ScrollController _homeScrollController;
  int _attentionSectionResetToken = 0;
  String? _lastTrackedLocation;
  VoidCallback? _routeListener;
  RouteInformationProvider? _routeInformationProvider;
  bool _motionConfigured = false;
  bool? _persistedFocusMode;
  bool _focusMode = true;
  bool _focusPreferenceLoaded = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboardingWizard();
      _bindDashboardReturnListener();
    });
  }

  Future<void> _loadFocusPreference() async {
    final persisted = await DashboardHomeFocusStore.load();
    if (!mounted) return;
    setState(() {
      _persistedFocusMode = persisted;
      _focusPreferenceLoaded = true;
      if (persisted != null) {
        _focusMode = persisted;
      }
    });
  }

  Future<void> _toggleFocusMode() async {
    final next = !_focusMode;
    setState(() {
      _focusMode = next;
      _persistedFocusMode = next;
    });
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
    final shouldRebuild = dashboardScrollVisualStateChanged(
      previousOffset: _homeScrollOffset,
      newOffset: offset,
    );
    _homeScrollOffset = offset;
    if (shouldRebuild) {
      setState(() {});
    }
  }

  void _bindDashboardReturnListener() {
    if (!mounted || _routeListener != null) return;
    final router = GoRouter.of(context);
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
    if (mounted) {
      setState(() {
        _loadingFin = true;
      });
    }
    try {
      final home = await ref.read(dashboardHomeProvider.future);
      if (!mounted) return;
      _applyFinanceData(home.financeiro);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingFin = false;
        });
        FeedbackHelper.showWarn(context, friendlyError(e));
      }
    }
  }

  void _applyFinanceData(FinanceiroDashboard data) {
    if (!mounted) return;
    setState(() {
      _finData = data;
      _loadingFin = false;
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
