import 'onboarding_status_data.dart';

class SetupStepCatalogEntry {
  const SetupStepCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.acao,
    required this.icon,
    required this.actionRoute,
    required this.estimatedMinutes,
    required this.isDone,
  });

  final String id;
  final String title;
  final String description;

  /// Texto do botão: diz o que acontece ao tocar.
  final String acao;
  final String icon;
  final String actionRoute;
  final int estimatedMinutes;
  final bool Function(OnboardingStatusData data) isDone;
}

/// Três passos, iguais em todo plano: o valor aparece quando o aluno recebe o
/// primeiro treino. O resto vira sugestão na Hoje ([setupProximaSugestao]).
final setupStepCatalog = [
  SetupStepCatalogEntry(
    id: 'primeiro-aluno',
    title: 'Cadastre seu primeiro aluno',
    description: 'Cadastre ou importe da concorrência.',
    acao: 'Cadastrar aluno',
    icon: 'person_add',
    actionRoute: '/alunos/novo',
    estimatedMinutes: 2,
    isDone: (d) => d.primeiroAlunoAdicionado,
  ),
  SetupStepCatalogEntry(
    id: 'primeiro-treino',
    title: 'Crie um treino',
    description: 'Escolha os dias e a divisão.',
    acao: 'Criar treino',
    icon: 'fitness_center',
    actionRoute: '/treinos?novo=1',
    estimatedMinutes: 3,
    isDone: (d) => d.primeiroTreinoCriado,
  ),
  SetupStepCatalogEntry(
    id: 'enviar-treino',
    title: 'Envie o treino para o aluno',
    description: 'Atribua o treino e o aluno já pode começar.',
    acao: 'Enviar treino',
    icon: 'send',
    actionRoute: '/alunos',
    estimatedMinutes: 1,
    isDone: (d) => d.treinoEnviado,
  ),
];

/// Depois dos três passos, uma sugestão por vez na Hoje.
class SetupSugestao {
  const SetupSugestao({
    required this.id,
    required this.title,
    required this.rota,
  });

  final String id;
  final String title;
  final String rota;
}

SetupSugestao? setupProximaSugestao(
  OnboardingStatusData data, {
  required bool podeCobrar,
  required bool temLanding,
  Set<String> dispensadas = const {},
}) {
  final sugestoes = [
    if (podeCobrar && !data.pagamentoConfigurado)
      const SetupSugestao(
        id: 'pagamento',
        title: 'Receba por PIX pelo app',
        rota: '/perfil/wallet',
      ),
    if (temLanding && !data.linkBioConfigurado)
      const SetupSugestao(
        id: 'link-bio',
        title: 'Crie sua página para captar alunos',
        rota: '/perfil/landing-editor',
      ),
  ];
  for (final s in sugestoes) {
    if (!dispensadas.contains(s.id)) return s;
  }
  return null;
}

SetupStepCatalogEntry? nextSetupStep(OnboardingStatusData data) {
  for (final step in setupStepCatalog) {
    if (!step.isDone(data)) return step;
  }
  return null;
}
