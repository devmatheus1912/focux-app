import '../../planos/data/planos_repository.dart';
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
    this.recurso,
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

  /// Recurso do plano exigido; trancado → passo some do checklist.
  final String? recurso;
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
    description: 'Monte do zero ou por um modelo rápido.',
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
    recurso: PlanoRecursoKeys.carteira,
  ),
  SetupStepCatalogEntry(
    id: 'pacote',
    title: 'Crie seu primeiro pacote',
    description: 'O que o aluno contrata com você.',
    icon: 'inventory_2',
    actionRoute: '/pacotes',
    estimatedMinutes: 2,
    isDone: (d) => d.pacoteCriado,
    recurso: PlanoRecursoKeys.loja,
  ),
  SetupStepCatalogEntry(
    id: 'habito',
    title: 'Configure hábitos',
    description: 'Rotina de check-in e aderência.',
    icon: 'repeat',
    actionRoute: '/habitos',
    estimatedMinutes: 2,
    isDone: (d) => d.habitoConfigurado,
    recurso: PlanoRecursoKeys.habitos,
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
    recurso: PlanoRecursoKeys.landing,
  ),
];

/// Ids de passo cujo recurso não está liberado no plano atual.
Set<String> setupStepsHiddenByPlan(bool Function(String recurso) liberado) => {
  for (final step in setupStepCatalog)
    if (step.recurso != null && !liberado(step.recurso!)) step.id,
};

/// Plano desconhecido não esconde nada (a tela de destino tem gate).
Set<String> setupStepsHiddenFor(PlanoFeatures? features) =>
    features == null
        ? const {}
        : setupStepsHiddenByPlan((k) => features.recurso(k).liberado);

/// Passos visíveis no plano atual (esconde link-bio sem capability e
/// passos em [hidden]).
List<SetupStepCatalogEntry> visibleSetupSteps({
  required bool landingCompleta,
  Set<String> hidden = const {},
}) {
  return setupStepCatalog
      .where(
        (step) =>
            (!step.requiresLandingCompleta || landingCompleta) &&
            !hidden.contains(step.id),
      )
      .toList(growable: false);
}

SetupStepCatalogEntry? nextSetupStep(
  OnboardingStatusData data, {
  bool landingCompleta = false,
  Set<String> hidden = const {},
}) {
  for (final step in visibleSetupSteps(
    landingCompleta: landingCompleta,
    hidden: hidden,
  )) {
    if (!step.isDone(data)) return step;
  }
  return null;
}