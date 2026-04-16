import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  Future<void> _handleUnauthenticated(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final vistoPrimeiroAcesso = prefs.getBool('onboarding_done') ?? false;
    if (!vistoPrimeiroAcesso) {
      await prefs.setBool('onboarding_done', true);
      if (context.mounted) context.go('/onboarding');
    } else {
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      if (next == AuthStatus.authenticated) {
        context.go('/dashboard/personal');
      } else if (next == AuthStatus.unauthenticated) {
        _handleUnauthenticated(context);
      }
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FOCUX',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
