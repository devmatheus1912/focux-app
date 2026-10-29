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
import '../widgets/splash_scene.dart';
import '../../../core/theme/focux_system_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeOut;

  SplashEstado _estado = SplashEstado.resolvendo;
  Timer? _demoraTimer;
  Timer? _travadaTimer;

  /// Cada tentativa tem um número; uma tentativa antiga não navega.
  int _tentativa = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeOut = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reduceMotion = TokensStrip.prefersReducedMotion(context);
      _fadeCtrl.duration = SplashMotionBudget(reduceMotion: _reduceMotion).fade;
      _iniciar();
    });
  }

  @override
  void dispose() {
    _demoraTimer?.cancel();
    _travadaTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _iniciar() {
    final tentativa = ++_tentativa;
    _demoraTimer?.cancel();
    _travadaTimer?.cancel();
    setState(() => _estado = SplashEstado.resolvendo);
    _demoraTimer = Timer(SplashMotionBudget.demora, () {
      if (mounted && tentativa == _tentativa) {
        setState(() => _estado = SplashEstado.demorando);
      }
    });
    _travadaTimer = Timer(SplashMotionBudget.travada, () {
      if (mounted && tentativa == _tentativa) {
        setState(() => _estado = SplashEstado.travada);
      }
    });
    _bootstrap(tentativa);
  }

  static const _resolveNavigationTimeout = Duration(seconds: 5);
  static const _profilePrefetchTimeout = Duration(seconds: 2);

  Future<void> _bootstrap(int tentativa) async {
    final target = await _resolveNavigationTarget().timeout(
      _resolveNavigationTimeout,
      onTimeout: () => _fallbackNavigationTarget(),
    );
    if (!mounted || tentativa != _tentativa) return;
    _demoraTimer?.cancel();
    _travadaTimer?.cancel();
    await _fadeCtrl.forward();
    if (!mounted || tentativa != _tentativa) return;
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

  Future<String> _resolveNavigationTarget() async {
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
    return splashPersonalTarget();
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
              child: PopScope(
                canPop: false,
                child: SplashScene(
                  estado: _estado,
                  fadeOut: _fadeOut,
                  onTentarNovamente: _iniciar,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
