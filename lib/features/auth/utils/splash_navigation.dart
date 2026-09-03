/// Destinos da splash — regra de sessão sem UI.
String splashGuestTarget({required bool onboardingDone}) =>
    onboardingDone ? '/login' : '/onboarding';

String splashAlunoTarget({
  required bool requiresPasswordChange,
  required bool activationSeen,
}) {
  if (requiresPasswordChange) return '/aluno/definir-senha';
  return activationSeen ? '/dashboard/aluno' : '/aluno/ativacao';
}

String splashPersonalTarget({
  required bool promoShown,
  required bool trialUsed,
  required String plano,
}) {
  final free = plano.trim().toUpperCase() == 'FREE';
  if (!promoShown && !trialUsed && free) return '/promo-enterprise';
  return '/dashboard/personal';
}

class SplashMotionBudget {
  const SplashMotionBudget({required this.compact, required this.reduceMotion});

  final bool compact;
  final bool reduceMotion;

  Duration get resolveDelay =>
      reduceMotion
          ? Duration.zero
          : Duration(milliseconds: compact ? 100 : 420);

  Duration get minVisible =>
      reduceMotion
          ? Duration.zero
          : Duration(milliseconds: compact ? 380 : 800);

  Duration get entry =>
      Duration(milliseconds: reduceMotion ? 0 : (compact ? 420 : 900));

  Duration get progress =>
      Duration(milliseconds: reduceMotion ? 0 : (compact ? 900 : 2200));

  Duration get fade =>
      Duration(milliseconds: reduceMotion ? 0 : (compact ? 240 : 340));

  Duration get progressFinish =>
      Duration(milliseconds: reduceMotion ? 0 : (compact ? 180 : 300));
}
