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

String splashPersonalTarget() => '/dashboard/personal';

/// A oferta do teste só aparece depois do primeiro aluno ou do primeiro treino.
bool deveOferecerTestePro({
  required bool promoShown,
  required bool trialUsed,
  required String plano,
  required int alunos,
  required int treinos,
}) {
  if (promoShown || trialUsed) return false;
  if (plano.trim().toUpperCase() != 'FREE') return false;
  return alunos > 0 || treinos > 0;
}

/// O que a splash mostra enquanto resolve o destino: nada animado; o
/// indicador e a mensagem só aparecem se demorar.
enum SplashEstado { resolvendo, demorando, travada }

/// Tempos da splash: sem espera mínima e sem animação decorativa.
class SplashMotionBudget {
  const SplashMotionBudget({required this.reduceMotion});

  final bool reduceMotion;

  /// Sem sinal de "carregando" antes disso.
  static const demora = Duration(milliseconds: 1200);

  /// Passado esse tempo, mensagem e "Tentar de novo".
  static const travada = Duration(seconds: 3);

  Duration get fade =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 150);
}
