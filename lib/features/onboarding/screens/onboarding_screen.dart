import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../auth/widgets/auth_shell.dart';

part 'onboarding_screen_widgets.part.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — FxIntroSlides (Onboarding) — Premium V2
// Staggered entry animations, visual metric anchors, spring physics
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _page = PageController();
  int _current = 0;
  OnboardingPersona _persona = OnboardingPersona.personal;

  PageController get _activePage => _page;

  late AnimationController _entryCtrl;
  late AnimationController _gridFadeCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleSlide;
  late Animation<double> _metricsSlide;
  late Animation<double> _fade;

  bool _motionConfigured = false;

  /// Telas ≤720px de altura útil — esconde metric chips no slide 1.
  static bool _isCompactLayout(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final padding = MediaQuery.paddingOf(context);
    return (height - padding.top - padding.bottom) < 720;
  }

  static const _pageIconsPersonal = [
    [
      Icons.dashboard_customize_rounded,
      Icons.fitness_center_rounded,
      Icons.insights_rounded,
    ],
    [Icons.psychology_rounded, Icons.pix_rounded, Icons.today_rounded],
  ];

  static const _pageIconsAluno = [
    [
      Icons.fitness_center_rounded,
      Icons.emoji_events_outlined,
      Icons.insights_rounded,
    ],
    [
      Icons.smart_toy_outlined,
      Icons.videocam_outlined,
      Icons.receipt_long_rounded,
    ],
  ];

  List<_OBData> _pagesFor(OnboardingPersona persona) {
    final slides = FocuxBrandCopy.slidesFor(persona);
    final icons =
        persona == OnboardingPersona.aluno
            ? _pageIconsAluno
            : _pageIconsPersonal;
    return List.generate(slides.length, (i) {
      final slide = slides[i];
      return _OBData(
        title: slide.title,
        titleHighlight: slide.titleHighlight,
        subtitle: slide.subtitle,
        metrics: List.generate(
          slide.metrics.length,
          (j) => _MetricChip(
            label: slide.metrics[j].label,
            value: slide.metrics[j].value,
            icon: icons[i][j],
          ),
        ),
        features: slide.features,
      );
    });
  }

  void _setupEntryAnimation({required bool reduceMotion}) {
    final iconCurve = reduceMotion ? Curves.easeOutCubic : Curves.elasticOut;
    _entryCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduceMotion ? 500 : 900),
    );
    _iconScale = Tween<double>(
      begin: reduceMotion ? 0.94 : 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(0.0, 0.5, curve: iconCurve),
      ),
    );
    _titleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _metricsSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _gridFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gridFadeCtrl.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    final reduce = reduceMotionOf(context);
    _setupEntryAnimation(reduceMotion: reduce);
    _gridFadeCtrl.duration = Duration(milliseconds: reduce ? 0 : 420);
    _entryCtrl.forward();
  }

  List<_OBData> get _pages => _pagesFor(_persona);

  @override
  void dispose() {
    _page.dispose();
    _entryCtrl.dispose();
    _gridFadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done_v3', true);
    await prefs.remove('onboarding_done_v2');
    await prefs.remove('onboarding_done');
  }

  Future<void> _skip() => _goLogin();

  Future<void> _finish() async {
    await _markDone();
    if (!mounted) return;
    if (_persona == OnboardingPersona.aluno) {
      context.go('/register/aluno');
    } else {
      context.go('/register');
    }
  }

  Future<void> _goLogin() async {
    await _markDone();
    if (!mounted) return;
    final role = _persona == OnboardingPersona.aluno ? 'aluno' : 'personal';
    context.go('/login?role=$role');
  }

  void _setPersona(OnboardingPersona persona) {
    if (_persona == persona) return;
    HapticFeedback.selectionClick();

    final currentIndex =
        _page.hasClients ? (_page.page?.round() ?? _current) : _current;
    final targetIndex = currentIndex.clamp(0, _pagesFor(persona).length - 1);

    setState(() {
      _persona = persona;
      _current = targetIndex;
    });
    if (_page.hasClients) {
      _page.jumpToPage(targetIndex);
    }
    _entryCtrl.forward(from: 0);
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_current < _pages.length - 1) {
      _activePage.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _onPageChanged(int i) {
    HapticFeedback.selectionClick();
    setState(() => _current = i);
    _entryCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final pages = _pages;
    final isLast = _current >= pages.length - 1;
    final textScaler = clampedTextScaler(context);
    final compact = _isCompactLayout(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: fxTransparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background ──
              Container(color: TokensStrip.cinematicBg),

              // Grid pattern — fade-in suave após splash flat
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _gridFadeCtrl,
                  curve: Curves.easeOutCubic,
                ),
                child: CustomPaint(
                  painter: _AuthGridPainter(),
                  size: Size.infinite,
                ),
              ),

              // ── Content ──
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: AuthRoleToggle(
                              isAluno: _persona == OnboardingPersona.aluno,
                              onPersonalTap:
                                  () => _setPersona(OnboardingPersona.personal),
                              onAlunoTap:
                                  () => _setPersona(OnboardingPersona.aluno),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Semantics(
                            button: true,
                            label: FocuxBrandCopy.onboardingSkip,
                            child: Material(
                              color: fxTransparent,
                              child: InkWell(
                                onTap: _skip,
                                borderRadius: BorderRadius.circular(99),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: heroTealSurface(0.04),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: heroTealInk().withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        FocuxBrandCopy.onboardingSkip,
                                        style: AppTypography.inter(
                                          color: heroTealInk().withValues(
                                            alpha: 0.70,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: heroTealInk().withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Semantics(
                        label: 'Slide ${_current + 1} de ${pages.length}',
                        child: PageView.builder(
                          clipBehavior: Clip.none,
                          controller: _activePage,
                          itemCount: pages.length,
                          onPageChanged: _onPageChanged,
                          itemBuilder:
                              (_, i) => _OBPageWidget(
                                key: ValueKey('${_persona.name}-$i'),
                                pageIndex: i,
                                persona: _persona,
                                data: pages[i],
                                compact: compact,
                                iconScale: _iconScale,
                                titleSlide: _titleSlide,
                                subtitleSlide: _subtitleSlide,
                                metricsSlide: _metricsSlide,
                                fade: _fade,
                              ),
                        ),
                      ),
                    ),

                    // Prova social só no primeiro slide — menos ruído nos demais
                    if (_current == 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: _OnboardingSocialProof(primary: primary),
                      )
                    else
                      const SizedBox(height: 4),

                    // Dots
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (i) => Semantics(
                            button: true,
                            selected: _current == i,
                            label: 'Ir para slide ${i + 1}',
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: GestureDetector(
                                  onTap:
                                      () => _activePage.animateToPage(
                                        i,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeOutCubic,
                                      ),
                                  child: _SlideDot(
                                    active: _current == i,
                                    primary: primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // CTA
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TokensStrip.s5,
                      ),
                      child: Column(
                        children: [
                          FxLiquidSecondaryButton(
                            label: FocuxBrandCopy.onboardingExistingAccountCta,
                            icon: Icons.login_rounded,
                            onPressed: _goLogin,
                          ),
                          const SizedBox(height: 10),
                          FxLiquidPrimaryButton(
                            label:
                                isLast
                                    ? FocuxBrandCopy.onboardingCtaFinish
                                    : FocuxBrandCopy.onboardingCtaNext,
                            onPressed: _next,
                          ),
                          if (isLast) ...[
                            const SizedBox(height: 8),
                            Text(
                              FocuxBrandCopy.onboardingCtaFinishHint,
                              textAlign: TextAlign.center,
                              style: AppTypography.inter(
                                color: heroTealSurface(0.78),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════
