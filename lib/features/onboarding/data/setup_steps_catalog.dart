import 'onboarding_status_data.dart';

class SetupStepCatalogEntry {
  const SetupStepCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionRoute,
    required this.estimatedMinutes,
    required this.isDone,
    this.requiresLandingCompleta = false,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String actionRoute;
  final int estimatedMinutes;
  final bool Function(OnboardingStatusData data) isDone;

  /// Passo de marketing (link/landing) — só no checklist com capability.
  final bool requiresLandingCompleta;
}

/// Ordem de ativação: aluno → treino → perfil operacional → PIX → pacote →
/// hábitos → link na bio (Enterprise). Espelha o guia canônico do produto;
/// o BFF `/wizard` é normalizado no cliente para esta ordem.
final setupStepCatalog = [
  SetupStepCatalogEntry(
    id: 'primeiro-aluno',
    title: 'Cadastre seu primeiro aluno',
    description: 'Cadastre ou importe da concorrência.',
    icon: 'person_add',
    actionRoute: '/alunos/novo',
    estimatedMinutes: 2,
    isDone: (d) => d.primeiroAlunoAdicionado,
  ),
  SetupStepCatalogEntry(
    id: 'primeiro-treino',
    title: 'Crie o primeiro treino',
    description: 'Monte na biblioteca ou gere com IA.',
    icon: 'fitness_center',
    actionRoute: '/treinos/novo',
    estimatedMinutes: 3,
    isDone: (d) => d.primeiroTreinoCriado,
  ),
  SetupStepCatalogEntry(
    id: 'perfil',
    title: 'Complete seu perfil',
    description: 'Foto, bio e contato profissional.',
    icon: 'person',
    actionRoute: '/perfil/editar',
    estimatedMinutes: 2,
    isDone: (d) => d.perfilCompleto,
  ),
  SetupStepCatalogEntry(
    id: 'pagamento',
    title: 'Configure o recebimento',
    description: 'Chave PIX para receber no app.',
    icon: 'attach_money',
    actionRoute: '/perfil/wallet',
    estimatedMinutes: 1,
    isDone: (d) => d.pagamentoConfigurado,
  ),
  SetupStepCatalogEntry(
    id: 'pacote',
    title: 'Crie seu primeiro pacote',
    description: 'O que o aluno contrata com você.',
    icon: 'inventory_2',
    actionRoute: '/pacotes',
    estimatedMinutes: 2,
    isDone: (d) => d.pacoteCriado,
  ),
  SetupStepCatalogEntry(
    id: 'habito',
    title: 'Configure hábitos',
    description: 'Rotina de check-in e aderência.',
    icon: 'repeat',
    actionRoute: '/habitos',
    estimatedMinutes: 2,
    isDone: (d) => d.habitoConfigurado,
  ),
  SetupStepCatalogEntry(
    id: 'link-bio',
    title: 'Crie seu link na bio',
    description: 'Página pública para captação.',
    icon: 'link',
    actionRoute: '/perfil/landing-editor',
    estimatedMinutes: 2,
    isDone: (d) => d.linkBioConfigurado,
    requiresLandingCompleta: true,
  ),
];

/// Passos visíveis no plano atual (esconde link/marca sem capability).
List<SetupStepCatalogEntry> visibleSetupSteps({
  required bool landingCompleta,
}) {
  return setupStepCatalog
      .where(
        (step) => !step.requiresLandingCompleta || landingCompleta,
      )
      .toList(growable: false);
}

SetupStepCatalogEntry? nextSetupStep(
  OnboardingStatusData data, {
  bool landingCompleta = false,
}) {
  for (final step in visibleSetupSteps(landingCompleta: landingCompleta)) {
    if (!step.isDone(data)) return step;
  }
  return null;
}

List<SetupStepCatalogEntry> pendingSetupSteps(
  OnboardingStatusData data, {
  bool landingCompleta = false,
}) {
  return visibleSetupSteps(landingCompleta: landingCompleta)
      .where((step) => !step.isDone(data))
      .toList();
}
