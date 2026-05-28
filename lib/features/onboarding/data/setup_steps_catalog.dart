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
    description:
        'Adicione cor da marca e descrição profissional para criar sua identidade visual.',
    icon: 'person',
    actionRoute: '/perfil/editar',
    estimatedMinutes: 2,
    isDone: (d) => d.perfilCompleto,
  ),
  SetupStepCatalogEntry(
    id: 'primeiro-aluno',
    title: 'Cadastre seu primeiro aluno',
    description:
        'Adicione um aluno manualmente ou importe da concorrência com a Migração Mágica.',
    icon: 'person_add',
    actionRoute: '/alunos/novo',
    estimatedMinutes: 2,
    isDone: (d) => d.primeiroAlunoAdicionado,
  ),
  SetupStepCatalogEntry(
    id: 'primeiro-treino',
    title: 'Crie o primeiro treino',
    description:
        'Monte um treino personalizado com exercícios da biblioteca ou gere com IA.',
    icon: 'fitness_center',
    actionRoute: '/treinos/novo',
    estimatedMinutes: 3,
    isDone: (d) => d.primeiroTreinoCriado,
  ),
  SetupStepCatalogEntry(
    id: 'pacote',
    title: 'Crie seu primeiro plano',
    description:
        'Monte um plano com preço e compartilhe o link no WhatsApp — como uma página sua na internet.',
    icon: 'inventory_2',
    actionRoute: '/pacotes',
    estimatedMinutes: 2,
    isDone: (d) => d.pacoteCriado,
  ),
  SetupStepCatalogEntry(
    id: 'habito',
    title: 'Configure hábitos',
    description: 'Crie hábitos para aumentar adesão e retenção dos alunos.',
    icon: 'repeat',
    actionRoute: '/habitos',
    estimatedMinutes: 2,
    isDone: (d) => d.habitoConfigurado,
  ),
  SetupStepCatalogEntry(
    id: 'pagamento',
    title: 'Configure o recebimento',
    description:
        'Adicione sua chave PIX para receber pagamentos automaticamente.',
    icon: 'attach_money',
    actionRoute: '/perfil/wallet',
    estimatedMinutes: 1,
    isDone: (d) => d.pagamentoConfigurado,
  ),
  SetupStepCatalogEntry(
    id: 'link-bio',
    title: 'Crie seu link na bio',
    description:
        'Monte sua landing page profissional e compartilhe para atrair novos alunos.',
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

const dashboardSetupPreviewLimit = 3;

List<SetupStepCatalogEntry> pendingSetupSteps(OnboardingStatusData data) {
  return setupStepCatalog.where((step) => !step.isDone(data)).toList();
}

List<SetupStepCatalogEntry> dashboardSetupPreview(OnboardingStatusData data) {
  return pendingSetupSteps(data).take(dashboardSetupPreviewLimit).toList();
}

int hiddenPendingSetupCount(OnboardingStatusData data) {
  final pending = pendingSetupSteps(data).length;
  final hidden = pending - dashboardSetupPreviewLimit;
  return hidden > 0 ? hidden : 0;
}
