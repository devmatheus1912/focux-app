import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../auth/widgets/auth_shell.dart';

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
    [
      Icons.psychology_rounded,
      Icons.pix_rounded,
      Icons.today_rounded,
    ],
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
    final iconCurve =
        reduceMotion ? Curves.easeOutCubic : Curves.elasticOut;
    _entryCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduceMotion ? 500 : 900),
    );
    _iconScale = Tween<double>(begin: reduceMotion ? 0.94 : 0.0, end: 1.0).animate(
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
    _gridFadeCtrl.duration = Duration(
      milliseconds: reduce ? 0 : 420,
    );
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
    final role =
        _persona == OnboardingPersona.aluno ? 'aluno' : 'personal';
    context.go('/login?role=$role');
  }

  void _setPersona(OnboardingPersona persona) {
    if (_persona == persona) return;
    HapticFeedback.selectionClick();

    final currentIndex =
        _page.hasClients ? (_page.page?.round() ?? _current) : _current;
    final targetIndex =
        currentIndex.clamp(0, _pagesFor(persona).length - 1);

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
        statusBarColor: Colors.transparent,
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
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _skip,
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      FocuxBrandCopy.onboardingSkip,
                                      style: AppTypography.inter(
                                        color: Colors.white.withValues(
                                          alpha: 0.70,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: Colors.white.withValues(
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
                    padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s5),
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
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        SizedBox(height: MediaQuery.paddingOf(context).bottom + 4),
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

class _MetricChip {
  final String label, value;
  final IconData icon;
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _OBData {
  final String title;
  final String titleHighlight;
  final String subtitle;
  final List<_MetricChip> metrics;
  final List<String> features;
  const _OBData({
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.metrics,
    required this.features,
  });
}

class _SlideDot extends StatelessWidget {
  final bool active;
  final Color primary;
  const _SlideDot({required this.active, required this.primary});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: active ? 28 : 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color:
            active ? primary : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE WIDGET — with staggered entry animations + metric chips
// ═══════════════════════════════════════════════════════════════════════════

class _OBPageWidget extends StatelessWidget {
  final int pageIndex;
  final OnboardingPersona persona;
  final _OBData data;
  final bool compact;
  final Animation<double> iconScale;
  final Animation<double> titleSlide;
  final Animation<double> subtitleSlide;
  final Animation<double> metricsSlide;
  final Animation<double> fade;

  const _OBPageWidget({
    super.key,
    required this.pageIndex,
    required this.persona,
    required this.data,
    required this.compact,
    required this.iconScale,
    required this.titleSlide,
    required this.subtitleSlide,
    required this.metricsSlide,
    required this.fade,
  });

  Widget _buildHero() {
    if (pageIndex == 0) {
      final width =
          compact
              ? (persona == OnboardingPersona.aluno ? 108.0 : 112.0)
              : (persona == OnboardingPersona.aluno ? 128.0 : 132.0);
      return FocuxOfficialLogo.full(width: width);
    }
    return FocuxOfficialLogo.full(width: compact ? 104.0 : 118.0);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final titleSize =
        pageIndex == 0 ? (compact ? 24.0 : 26.0) : (compact ? 25.0 : 27.0);
    final showMetrics = pageIndex == 0 && !compact;

    return AnimatedBuilder(
      animation: fade,
      builder:
          (_, __) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              pageIndex == 0 ? (compact ? 0 : 2) : (compact ? 6 : 10),
              20,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: iconScale.value,
                  alignment: Alignment.center,
                  child: _buildHero(),
                ),

                if (pageIndex == 0) ...[
                  SizedBox(height: compact ? 4 : 8),
                  Transform.translate(
                    offset: Offset(0, subtitleSlide.value * 0.5),
                    child: Opacity(
                      opacity: fade.value.clamp(0.0, 1.0),
                      child: _OnboardingHook(
                        primary: primary,
                        aluno: persona == OnboardingPersona.aluno,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: pageIndex == 0 ? (compact ? 8 : 12) : 14),

                Transform.translate(
                  offset: Offset(0, titleSlide.value),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.inter(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                          height: 1.14,
                        ),
                        children: [
                          TextSpan(text: data.title),
                          TextSpan(
                            text: data.titleHighlight,
                            style: TextStyle(color: primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Transform.translate(
                  offset: Offset(0, subtitleSlide.value),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        data.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.48,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: pageIndex == 0 ? (compact ? 10 : 14) : 12),

                if (showMetrics)
                  Transform.translate(
                    offset: Offset(0, metricsSlide.value),
                    child: Opacity(
                      opacity: fade.value.clamp(0.0, 1.0),
                      child: Row(
                        children:
                            data.metrics
                                .map(
                                  (m) => Expanded(
                                    child: _MetricChipWidget(
                                      metric: m,
                                      primary: primary,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),

                if (showMetrics) const SizedBox(height: 10),

                Transform.translate(
                  offset: Offset(0, metricsSlide.value * 0.7),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: pageIndex == 0 ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        children:
                            data.features.asMap().entries.map((e) {
                              final isLast = e.key == data.features.length - 1;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 9,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: AppTypography.inter(
                                          color: Colors.white.withValues(
                                            alpha: 0.82,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.38,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _OnboardingSocialProof extends StatelessWidget {
  const _OnboardingSocialProof({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: FocuxBrandCopy.onboardingSocialProof,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 14, color: primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                FocuxBrandCopy.onboardingSocialProof,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHook extends StatelessWidget {
  const _OnboardingHook({required this.primary, this.aluno = false});

  final Color primary;
  final bool aluno;

  @override
  Widget build(BuildContext context) {
    final hook =
        aluno ? FocuxBrandCopy.onboardingHookAluno : FocuxBrandCopy.onboardingHook;
    final highlight =
        aluno
            ? FocuxBrandCopy.onboardingHookAlunoHighlight
            : FocuxBrandCopy.onboardingHookHighlight;
    final prefix = hook.substring(0, hook.length - highlight.length);

    return Semantics(
      label: hook,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.inter(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              letterSpacing: 0.06,
            ),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                text: highlight,
                style: TextStyle(
                  color: primary.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
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
// METRIC CHIP — visual anchor replacing dead space
// ═══════════════════════════════════════════════════════════════════════════

class _MetricChipWidget extends StatelessWidget {
  final _MetricChip metric;
  final Color primary;
  const _MetricChipWidget({required this.metric, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(metric.icon, color: primary, size: 18),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: AppTypography.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.inter(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID
// ═══════════════════════════════════════════════════════════════════════════

class _AuthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = EagleTokens.brandAccent.withValues(alpha: 0.045)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

