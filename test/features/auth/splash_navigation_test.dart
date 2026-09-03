import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/splash_navigation.dart';

void main() {
  test('convidado vai ao onboarding ou login', () {
    expect(splashGuestTarget(onboardingDone: false), '/onboarding');
    expect(splashGuestTarget(onboardingDone: true), '/login');
  });

  test('aluno prioriza senha definitiva e ativação', () {
    expect(
      splashAlunoTarget(requiresPasswordChange: true, activationSeen: false),
      '/aluno/definir-senha',
    );
    expect(
      splashAlunoTarget(requiresPasswordChange: false, activationSeen: false),
      '/aluno/ativacao',
    );
    expect(
      splashAlunoTarget(requiresPasswordChange: false, activationSeen: true),
      '/dashboard/aluno',
    );
  });

  test('personal FREE sem promo cai na oferta; o resto na Home', () {
    expect(
      splashPersonalTarget(promoShown: false, trialUsed: false, plano: 'free'),
      '/promo-enterprise',
    );
    expect(
      splashPersonalTarget(promoShown: true, trialUsed: false, plano: 'FREE'),
      '/dashboard/personal',
    );
    expect(
      splashPersonalTarget(promoShown: false, trialUsed: true, plano: 'FREE'),
      '/dashboard/personal',
    );
    expect(
      splashPersonalTarget(promoShown: false, trialUsed: false, plano: 'PRO'),
      '/dashboard/personal',
    );
  });

  test('reduced motion zera espera da splash', () {
    const budget = SplashMotionBudget(compact: false, reduceMotion: true);
    expect(budget.resolveDelay, Duration.zero);
    expect(budget.minVisible, Duration.zero);
    expect(budget.entry, Duration.zero);
    expect(budget.progress, Duration.zero);
    expect(budget.fade, Duration.zero);
    expect(budget.progressFinish, Duration.zero);
  });
}
