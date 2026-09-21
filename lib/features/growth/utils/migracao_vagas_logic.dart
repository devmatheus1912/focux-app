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

String migracaoVagasHint({
  required int? limiteAlunos,
  required int alunosAtuais,
  required int novosParaImportar,
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
  return 'Só cabem $rest vagas no plano (${snap.limiteAlunos}). '
      'Remova ${snap.excedentes} ou faça upgrade.';
}
