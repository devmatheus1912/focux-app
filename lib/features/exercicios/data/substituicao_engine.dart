import 'enums.dart';
import 'exercicio_repository.dart';

class AlternativaResultado {
  final Exercicio exercicio;
  final int score;

  const AlternativaResultado(this.exercicio, this.score);
}

class SubstituicaoEngine {
  static const int scoreMinimo = 50;
  static const int topN = 5;

  List<AlternativaResultado> encontrarAlternativas({
    required Exercicio alvo,
    required List<Exercicio> candidatos,
    Set<Equipamento>? equipamentosAluno,
  }) {
    final scored = <AlternativaResultado>[];

    for (final candidato in candidatos) {
      if (!_passaFiltro(alvo, candidato, equipamentosAluno)) continue;
      final score = _score(alvo, candidato, equipamentosAluno);
      if (score >= scoreMinimo) {
        scored.add(AlternativaResultado(candidato, score));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.exercicio.nome.compareTo(b.exercicio.nome);
    });
    return scored.take(topN).toList();
  }

  bool _passaFiltro(
    Exercicio alvo,
    Exercicio candidato,
    Set<Equipamento>? equipamentosAluno,
  ) {
    if (candidato.id == alvo.id) return false;
    if (alvo.modalidade != null && candidato.modalidade != alvo.modalidade) {
      return false;
    }
    if (equipamentosAluno != null && equipamentosAluno.isNotEmpty) {
      return candidato.equipamentos.any(equipamentosAluno.contains);
    }
    return true;
  }

  int _score(
    Exercicio alvo,
    Exercicio candidato,
    Set<Equipamento>? equipamentosAluno,
  ) {
    var score = 100;

    if (alvo.padraoMovimento != null &&
        candidato.padraoMovimento != alvo.padraoMovimento) {
      score -= 50;
    }
    if (alvo.grupoMuscularPrimario != null &&
        candidato.grupoMuscularPrimario != alvo.grupoMuscularPrimario) {
      score -= 25;
    }
    if (alvo.dificuldade != null && candidato.dificuldade != null) {
      score -=
          10 * (alvo.dificuldade!.index - candidato.dificuldade!.index).abs();
    }
    if (alvo.unilateral != candidato.unilateral) {
      score -= 5;
    }

    final overlapSecundario =
        candidato.gruposSecundarios
            .where(alvo.gruposSecundarios.contains)
            .length;
    score += overlapSecundario * 10;

    if (equipamentosAluno != null &&
        equipamentosAluno.isNotEmpty &&
        candidato.equipamentos.isNotEmpty) {
      final match =
          candidato.equipamentos.where(equipamentosAluno.contains).length;
      final ratio = match / candidato.equipamentos.length;
      score -= ((1 - ratio) * 5).round();
    }

    return score;
  }
}
