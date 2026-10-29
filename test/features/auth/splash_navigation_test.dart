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

  test('a splash do personal abre a Home', () {
    expect(splashPersonalTarget(), '/dashboard/personal');
  });

  test('o teste só aparece depois do primeiro aluno ou treino', () {
    expect(
      deveOferecerTestePro(
        promoShown: false,
        trialUsed: false,
        plano: 'FREE',
        alunos: 0,
        treinos: 0,
      ),
      isFalse,
    );
    expect(
      deveOferecerTestePro(
        promoShown: false,
        trialUsed: false,
        plano: 'free',
        alunos: 1,
        treinos: 0,
      ),
      isTrue,
    );
    expect(
      deveOferecerTestePro(
        promoShown: false,
        trialUsed: false,
        plano: 'FREE',
        alunos: 0,
        treinos: 1,
      ),
      isTrue,
    );
    expect(
      deveOferecerTestePro(
        promoShown: true,
        trialUsed: false,
        plano: 'FREE',
        alunos: 3,
        treinos: 2,
      ),
      isFalse,
    );
    expect(
      deveOferecerTestePro(
        promoShown: false,
        trialUsed: false,
        plano: 'PRO',
        alunos: 2,
        treinos: 1,
      ),
      isFalse,
    );
  });

  test('splash não tem espera mínima: só um fade curto', () {
    const normal = SplashMotionBudget(reduceMotion: false);
    expect(normal.fade, const Duration(milliseconds: 150));
    const reduzido = SplashMotionBudget(reduceMotion: true);
    expect(reduzido.fade, Duration.zero);
    expect(SplashMotionBudget.demora, const Duration(milliseconds: 1200));
    expect(SplashMotionBudget.travada, const Duration(seconds: 3));
  });
}
