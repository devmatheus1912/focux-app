import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/brand/brand_pulse.dart';
import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../auth/widgets/auth_shell.dart';
import '../data/brand_pulse_repository.dart';

part 'onboarding_screen_widgets.part.dart';

/// Onboarding pré-login — 2 slides × Personal/Aluno.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.socialProofLoader});

  /// Override em testes; null usa [BrandPulseRepository].
  final Future<List<BrandSocialProofItem>> Function()? socialProofLoader;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const _personaKey = 'onboarding_persona_v3';
  static const _slideKey = 'onboarding_slide_v3';

  final _page = PageController();
  int _current = 0;
  OnboardingPersona _persona = OnboardingPersona.personal;
  String _socialProofLine = FocuxBrandCopy.onboardingSocialProofFallback;

  PageController get _activePage => _page;

  late AnimationController _entryCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleSlide;
  late Animation<double> _metricsSlide;
  late Animation<double> _fade;

  bool _motionConfigured = false;

  /// Telas ≤760px de altura útil — logo/tipografia mais compactos.
  static bool _isCompactLayout(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final padding = MediaQuery.paddingOf(context);
    return (height - padding.top - padding.bottom) < 760;
  }

  List<_OBData> _pagesFor(OnboardingPersona persona) {
    final slides = FocuxBrandCopy.slidesFor(persona);
    return List.generate(slides.length, (i) {
      final slide = slides[i];
      return _OBData(
        title: slide.title,
        titleHighlight: slide.titleHighlight,
        subtitle: slide.subtitle,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restoreProgress();
      _loadSocialProof();
    });
  }

  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_personaKey);
    final slide = prefs.getInt(_slideKey) ?? 0;
    if (!mounted) return;
    final persona =
        raw == OnboardingPersona.aluno.name
            ? OnboardingPersona.aluno
            : OnboardingPersona.personal;
    final pages = _pagesFor(persona);
    final index = slide.clamp(0, pages.length - 1);
    setState(() {
      _persona = persona;
      _current = index;
    });
    if (_page.hasClients) {
      _page.jumpToPage(index);
    }
  }

  Future<void> _persistProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, _persona.name);
    await prefs.setInt(_slideKey, _current);
  }

  Future<void> _loadSocialProof() async {
    try {
      final loader =
          widget.socialProofLoader ??
          () => BrandPulseRepository(ApiClient()).fetchSocialProof();
      final items = await loader().timeout(const Duration(milliseconds: 2500));
      final line = formatBrandSocialProofLine(items);
      if (!mounted) return;
      if (line != _socialProofLine) {
        setState(() => _socialProofLine = line);
      }
    } catch (_) {
      // Mantém fallback neutro — onboarding não depende de rede.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    final reduce = reduceMotionOf(context);
    _setupEntryAnimation(reduceMotion: reduce);
    _entryCtrl.forward();
  }

  List<_OBData> get _pages => _pagesFor(_persona);

  @override
  void dispose() {
    _page.dispose();
    _entryCtrl.dispose();
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
    _persistProgress();
    if (_page.hasClients) {
      _page.jumpToPage(targetIndex);
    }
    _entryCtrl.forward(from: 0);
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_current < _pages.length - 1) {
      if (reduceMotionOf(context)) {
        _activePage.jumpToPage(_current + 1);
      } else {
        _activePage.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      _finish();
    }
  }

  void _onPageChanged(int i) {
    HapticFeedback.selectionClick();
    setState(() => _current = i);
    _entryCtrl.forward(from: 0);
    _persistProgress();
  }

  void _back() {
    if (_current <= 0) {
      _skip();
      return;
    }
    HapticFeedback.selectionClick();
    if (reduceMotionOf(context)) {
      _activePage.jumpToPage(_current - 1);
    } else {
      _activePage.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final pages = _pages;
    final isLast = _current >= pages.length - 1;
    final textScaler = clampedTextScaler(context);
    final compact = _isCompactLayout(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: fxScreenA11yScope(
      label: 'Boas-vindas Focux',
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: Scaffold(
          body: AuthShell(
            child: Column(
              children: [
                _OnboardingHeader(
                  persona: _persona,
                  onPersonaChanged: _setPersona,
                  onSkip: _skip,
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
                _OnboardingFooter(
                  primary: primary,
                  pageCount: pages.length,
                  current: _current,
                  isLast: isLast,
                  persona: _persona,
                  socialProofLine: _current == 0 ? _socialProofLine : null,
                  onDotTap:
                      (i) =>
                          reduceMotionOf(context)
                              ? _activePage.jumpToPage(i)
                              : _activePage.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              ),
                  onBack: _current > 0 ? _back : null,
                  onLogin: _goLogin,
                  onPrimary: _next,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
