import 'package:focux_app/features/subscription/models/subscription_plan.dart';

/// Regras puras de vagas na migração mágica (FREE 3 / PRO 30 / Enterprise null).
class MigracaoVagasSnapshot {
  const MigracaoVagasSnapshot({
    required this.alunosAtuais,
    required this.limiteAlunos,
    required this.novosParaImportar,
  });

  final int alunosAtuais;
  final int? limiteAlunos;
  final int novosParaImportar;

  bool get isUnlimited => limiteAlunos == null || limiteAlunos! <= 0;

  int? get vagasRestantes {
    if (isUnlimited) return null;
    return (limiteAlunos! - alunosAtuais).clamp(0, limiteAlunos!);
  }

  bool get cabeNoPlano {
    if (isUnlimited) return true;
    return alunosAtuais + novosParaImportar <= limiteAlunos!;
  }

  int get excedentes {
    if (isUnlimited) return 0;
    final over = alunosAtuais + novosParaImportar - limiteAlunos!;
    return over > 0 ? over : 0;
  }
}

/// Free estoura → Pro. Pro em 30 → Enterprise. Enterprise não paywall de vagas.
SubscriptionPlan? upgradePlanoParaMaisVagas(SubscriptionPlan? planoAtual) {
  switch (planoAtual) {
    case SubscriptionPlan.FREE:
    case null:
      return SubscriptionPlan.PRO;
    case SubscriptionPlan.PRO:
      return SubscriptionPlan.ENTERPRISE;
    case SubscriptionPlan.ENTERPRISE:
      return null;
  }
}

String migracaoVagasHint({
  required int? limiteAlunos,
  required int alunosAtuais,
  required int novosParaImportar,
  SubscriptionPlan? planoAtual,
}) {
  final snap = MigracaoVagasSnapshot(
    alunosAtuais: alunosAtuais,
    limiteAlunos: limiteAlunos,
    novosParaImportar: novosParaImportar,
  );
  if (snap.isUnlimited) {
    return 'Plano ilimitado — pode importar todos os $novosParaImportar.';
  }
  final rest = snap.vagasRestantes ?? 0;
  if (snap.cabeNoPlano) {
    return 'Cabem $rest de ${snap.limiteAlunos} vagas. Importando $novosParaImportar.';
  }
  final alvo = upgradePlanoParaMaisVagas(planoAtual);
  final alvoLabel = switch (alvo) {
    SubscriptionPlan.ENTERPRISE => 'Enterprise',
    SubscriptionPlan.PRO => 'Pro',
    _ => 'um plano superior',
  };
  return 'Só cabem $rest vagas no plano (${snap.limiteAlunos}). '
      'Remova ${snap.excedentes} ou faça upgrade para $alvoLabel.';
}
