import '../../../l10n/app_localizations.dart';

typedef DashboardActivationStep = ({
  String title,
  String body,
  String cta,
  String route,
});

/// Próximo passo de ativação da Hoje; a copy descreve o que a rota entrega.
DashboardActivationStep? dashboardActivationStep(
  S s, {
  required int alunosAtivos,
  required bool temTreinos,
  required bool temFinanceiro,
}) {
  if (alunosAtivos == 0) {
    return (
      title: s.ativacaoImportarTitulo,
      body: s.ativacaoImportarCorpo,
      cta: s.ativacaoImportarCta,
      route: '/growth/migracao',
    );
  }
  if (!temTreinos) {
    return (
      title: s.ativacaoTreinoTitulo,
      body: s.ativacaoTreinoCorpo,
      cta: s.ativacaoTreinoCta,
      route: '/treinos/novo',
    );
  }
  if (!temFinanceiro) {
    return (
      title: s.ativacaoFinanceiroTitulo,
      body: s.ativacaoFinanceiroCorpo,
      cta: s.ativacaoFinanceiroCta,
      route: '/financeiro',
    );
  }
  return null;
}
