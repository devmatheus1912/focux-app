import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../alunos/providers/alunos_provider.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) {
      return;
    }

    final authStatus = ref.read(authProvider);
    if (authStatus == AuthStatus.authenticated) {
      await _handleAuthenticated();
      return;
    }

    await _handleUnauthenticated();
  }

  Future<void> _handleAuthenticated() async {
    final role = ref.read(userRoleProvider);
    if (role == UserRole.aluno) {
      final requiresPasswordChange = ref.read(requiresPasswordChangeProvider);
      if (!mounted) {
        return;
      }
      if (!requiresPasswordChange) {
        try {
          final aluno = await ref.read(alunoMeProvider.future);
          final prefs = await SharedPreferences.getInstance();
          final onboardingSeen =
              prefs.getBool('aluno_activation_seen_${aluno.id}') ?? false;
          if (!mounted) {
            return;
          }
          context.go(onboardingSeen ? '/dashboard/aluno' : '/aluno/ativacao');
          return;
        } catch (_) {
          if (mounted) {
            context.go('/dashboard/aluno');
          }
          return;
        }
      }
      context.go(
        requiresPasswordChange ? '/aluno/definir-senha' : '/dashboard/aluno',
      );
      return;
    }

    try {
      final perfil = await ref.read(perfilProvider.future);
      final prefs = await SharedPreferences.getInstance();
      final promoShown = prefs.getBool('promo_shown_${perfil.id}') ?? false;
      final trialUsed = perfil.trialUsed ?? false;
      final plano = perfil.plano.toUpperCase();

      if (!mounted) {
        return;
      }

      if (!promoShown && !trialUsed && plano == 'FREE') {
        context.go('/promo-enterprise');
      } else {
        context.go('/dashboard/personal');
      }
    } catch (_) {
      if (mounted) {
        context.go('/dashboard/personal');
      }
    }
  }

  Future<void> _handleUnauthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done_v3') ?? false;

    if (!mounted) {
      return;
    }

    if (onboardingDone) {
      context.go('/login');
      return;
    }

    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(body: AuthShell(child: _SplashBody())),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 52),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const AuthLogoMark(size: 140),
          const SizedBox(height: 32),
          const AuthWordmark(titleSize: 38, subtitleSize: 14, taglineSize: 13),
          const Spacer(flex: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isActive = index == 0;
              return Container(
                width: isActive ? 28 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: isActive ? 1 : index == 1 ? 0.4 : 0.2,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
