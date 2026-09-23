import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../alunos/providers/alunos_provider.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../../exercicios/services/biblioteca_bootstrap.dart';
import '../../dashboard/utils/aluno_dashboard_home_prefetch.dart';
import '../../dashboard/utils/dashboard_home_prefetch.dart';
import '../../alunos/utils/alunos_home_prefetch.dart';
import '../providers/auth_provider.dart';
import '../utils/splash_navigation.dart';
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
      if (!mounted) return;
      final reduceMotion = TokensStrip.prefersReducedMotion(context);
      if (!reduceMotion) {
        _ambientCtrl.repeat();
      }
      final compact = await _resolveQuickSplash();
      if (!mounted) return;
      final budget = SplashMotionBudget(
        compact: compact,
        reduceMotion: reduceMotion,
      );
      if (compact) {
        setState(() => _compactSplash = true);
      }
      _entryCtrl.duration = budget.entry;
      _progressCtrl.duration = budget.progress;
      _fadeCtrl.duration = budget.fade;
      _entryCtrl.forward();
      _bootstrap(budget);
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

  static const _resolveNavigationTimeout = Duration(seconds: 5);
  static const _profilePrefetchTimeout = Duration(seconds: 2);

  Future<void> _bootstrap(SplashMotionBudget budget) async {
    final bootstrapFuture = _resolveNavigationTarget(budget).timeout(
      _resolveNavigationTimeout,
      onTimeout: () => _fallbackNavigationTarget(),
    );
    // Mid progress em paralelo — não espera 0.92 antes de fechar a barra.
    if (budget.progress == Duration.zero) {
      _progressCtrl.value = 0.62;
    } else {
      unawaited(_progressCtrl.animateTo(0.62, curve: Curves.easeOutCubic));
    }
    final minDelay = Future<void>.delayed(budget.minVisible);

    final target = await bootstrapFuture;
    await minDelay;
    if (!mounted) return;

    await _progressCtrl.animateTo(
      1,
      duration: budget.progressFinish,
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    await _fadeCtrl.forward();
    if (!mounted) return;

    context.go(target);
  }

  Future<void> _awaitAuthSettled() async {
    if (ref.read(authProvider) != AuthStatus.unknown) return;
    final deadline = DateTime.now().add(_resolveNavigationTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      if (ref.read(authProvider) != AuthStatus.unknown) return;
    }
  }

  Future<String> _fallbackNavigationTarget() async {
    final authStatus = ref.read(authProvider);
    if (authStatus == AuthStatus.authenticated) {
      final role = ref.read(userRoleProvider);
      if (role == UserRole.aluno) return '/dashboard/aluno';
      return '/dashboard/personal';
    }
    if (authStatus == AuthStatus.unauthenticated) {
      return _unauthenticatedTarget();
    }
    return splashGuestTarget(onboardingDone: false);
  }

  Future<String> _resolveNavigationTarget(SplashMotionBudget budget) async {
    await Future<void>.delayed(budget.resolveDelay);
    await _awaitAuthSettled();

    final authStatus = ref.read(authProvider);
    if (authStatus == AuthStatus.authenticated) {
      return _authenticatedTarget();
    }
    if (authStatus == AuthStatus.unauthenticated) {
      return _unauthenticatedTarget();
    }
    return await _fallbackNavigationTarget();
  }

  Future<String> _authenticatedTarget() async {
    final role = ref.read(userRoleProvider);
    if (role == UserRole.aluno) {
      unawaited(prefetchAlunoDashboardHome(ref));
      final requiresPasswordChange = ref.read(requiresPasswordChangeProvider);
      if (requiresPasswordChange) {
        return splashAlunoTarget(
          requiresPasswordChange: true,
          activationSeen: false,
        );
      }

      try {
        final aluno = await ref
            .read(alunoMeProvider.future)
            .timeout(_profilePrefetchTimeout);
        final prefs = await SharedPreferences.getInstance();
        final onboardingSeen =
            prefs.getBool('aluno_activation_seen_${aluno.id}') ?? false;
        return splashAlunoTarget(
          requiresPasswordChange: false,
          activationSeen: onboardingSeen,
        );
      } catch (_) {
        return '/dashboard/aluno';
      }
    }

    prefetchPersonalDashboardHome(ref);
    prefetchAlunosHome(ref);
    // Prefetch em background — cold start não espera rede do perfil.
    unawaited(
      ref.read(perfilProvider.future).timeout(_profilePrefetchTimeout).then((
        perfil,
      ) {
        if (!mounted) return;
        BibliotecaBootstrap.ensureReadyWithContainer(
          ProviderScope.containerOf(context),
        );
      }).catchError((_) {}),
    );
    try {
      final perfil = await ref
          .read(perfilProvider.future)
          .timeout(const Duration(milliseconds: 450));
      if (!mounted) return '/dashboard/personal';
      final prefs = await SharedPreferences.getInstance();
      final promoShown = prefs.getBool('promo_shown_${perfil.id}') ?? false;
      return splashPersonalTarget(
        promoShown: promoShown,
        trialUsed: perfil.trialUsed ?? false,
        plano: perfil.plano,
      );
    } catch (_) {
      return '/dashboard/personal';
    }
  }

  Future<String> _unauthenticatedTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done_v3') ?? false;
    return splashGuestTarget(onboardingDone: onboardingDone);
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Focux',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: FocuxSystemChrome.dark,
        child: PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: TokensStrip.cinematicBg,
            extendBody: true,
            body: AuthShell(
              animateGridIn: false,
              child: PopScope(
                canPop: false,
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
        ),
      ),
    );
  }
}
