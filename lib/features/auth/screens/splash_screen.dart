import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../alunos/providers/alunos_provider.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../../exercicios/services/biblioteca_bootstrap.dart';
import '../../dashboard/utils/dashboard_home_prefetch.dart';
import '../../alunos/utils/alunos_home_prefetch.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/cinematic_splash_scene.dart';
import '../../../core/theme/focux_system_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambientCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _fadeCtrl;

  late final Animation<double> _fadeOut;

  bool _compactSplash = false;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    _fadeOut = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !TokensStrip.prefersReducedMotion(context)) {
        _ambientCtrl.repeat();
      }
      final compact = await _resolveQuickSplash();
      if (!mounted) return;
      if (compact) {
        setState(() => _compactSplash = true);
        _entryCtrl.duration = const Duration(milliseconds: 420);
        _progressCtrl.duration = const Duration(milliseconds: 900);
        _fadeCtrl.duration = const Duration(milliseconds: 240);
      }
      _entryCtrl.forward();
      _bootstrap(compact: compact);
    });
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<bool> _resolveQuickSplash() async {
    if (ref.read(authProvider) == AuthStatus.authenticated) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_done_v3') ?? false;
  }

  Future<void> _bootstrap({required bool compact}) async {
    final bootstrapFuture = _resolveNavigationTarget(quick: compact);
    final progressFuture = _progressCtrl.animateTo(
      0.92,
      curve: Curves.easeOutCubic,
    );
    final minDelay = Future<void>.delayed(
      Duration(milliseconds: compact ? 380 : 800),
    );

    final target = await bootstrapFuture;
    await Future.wait([progressFuture, minDelay]);
    if (!mounted) return;

    await _progressCtrl.animateTo(
      1,
      duration: Duration(milliseconds: compact ? 180 : 300),
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    await _fadeCtrl.forward();
    if (!mounted) return;

    context.go(target);
  }

  Future<String> _resolveNavigationTarget({bool quick = false}) async {
    await Future<void>.delayed(Duration(milliseconds: quick ? 100 : 420));

    final authStatus = ref.read(authProvider);
    if (authStatus == AuthStatus.authenticated) {
      return _authenticatedTarget();
    }
    return _unauthenticatedTarget();
  }

  Future<String> _authenticatedTarget() async {
    final role = ref.read(userRoleProvider);
    if (role == UserRole.aluno) {
      final requiresPasswordChange = ref.read(requiresPasswordChangeProvider);
      if (requiresPasswordChange) {
        return '/aluno/definir-senha';
      }

      try {
        final aluno = await ref.read(alunoMeProvider.future);
        final prefs = await SharedPreferences.getInstance();
        final onboardingSeen =
            prefs.getBool('aluno_activation_seen_${aluno.id}') ?? false;
        return onboardingSeen ? '/dashboard/aluno' : '/aluno/ativacao';
      } catch (_) {
        return '/dashboard/aluno';
      }
    }

    try {
      prefetchPersonalDashboardHome(ref);
      prefetchAlunosHome(ref);
      final perfil = await ref.read(perfilProvider.future);
      if (!mounted) return '/dashboard/personal';
      BibliotecaBootstrap.ensureReadyWithContainer(
        ProviderScope.containerOf(context),
      );
      final prefs = await SharedPreferences.getInstance();
      final promoShown = prefs.getBool('promo_shown_${perfil.id}') ?? false;
      final trialUsed = perfil.trialUsed ?? false;
      final plano = perfil.plano.toUpperCase();

      if (!promoShown && !trialUsed && plano == 'FREE') {
        return '/promo-enterprise';
      }
      return '/dashboard/personal';
    } catch (_) {
      return '/dashboard/personal';
    }
  }

  Future<String> _unauthenticatedTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done_v3') ?? false;
    return onboardingDone ? '/login' : '/onboarding';
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Focux',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: FocuxSystemChrome.dark,
        child: Scaffold(
          backgroundColor: TokensStrip.cinematicBg,
          extendBody: true,
          body: AuthShell(
            animateGridIn: false,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _ambientCtrl,
                _entryCtrl,
                _progressCtrl,
                _fadeCtrl,
              ]),
              builder:
                  (context, _) => CinematicSplashScene(
                    progress: _progressCtrl.value,
                    ambient: _ambientCtrl,
                    entry: _entryCtrl,
                    fadeOut: _fadeOut,
                    compact: _compactSplash,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
