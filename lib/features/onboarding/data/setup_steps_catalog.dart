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
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String actionRoute;
  final int estimatedMinutes;
  final bool Function(OnboardingStatusData data) isDone;
}

/// Espelha as 7 etapas do backend (`OnboardingService.getGuide`).
final setupStepCatalog = [
  SetupStepCatalogEntry(
    id: 'perfil',
    title: 'Complete seu perfil',
    description: 'Cor da marca e bio profissional.',
    icon: 'person',
    actionRoute: '/perfil/editar',
    estimatedMinutes: 2,
    isDone: (d) => d.perfilCompleto,
  ),
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
    id: 'pagamento',
    title: 'Configure o recebimento',
    description: 'Chave PIX para receber no app.',
    icon: 'attach_money',
    actionRoute: '/perfil/wallet',
    estimatedMinutes: 1,
    isDone: (d) => d.pagamentoConfigurado,
  ),
  SetupStepCatalogEntry(
    id: 'link-bio',
    title: 'Crie seu link na bio',
    description: 'Página pública para captação.',
    icon: 'link',
    actionRoute: '/perfil/landing-editor',
    estimatedMinutes: 2,
    isDone: (d) => d.linkBioConfigurado,
  ),
];

SetupStepCatalogEntry? nextSetupStep(OnboardingStatusData data) {
  for (final step in setupStepCatalog) {
    if (!step.isDone(data)) return step;
  }
  return null;
}

List<SetupStepCatalogEntry> pendingSetupSteps(OnboardingStatusData data) {
  return setupStepCatalog.where((step) => !step.isDone(data)).toList();
}
