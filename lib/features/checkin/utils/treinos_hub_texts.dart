import '../../../l10n/app_localizations.dart';
import '../../dashboard/utils/aluno_home_texts.dart';
import '../../dashboard/utils/aluno_pendencias.dart';
import '../../treinos/utils/treino_atribuicao_prazo.dart';
import '../data/checkin_repository.dart';
import 'treino_ficha_status.dart';
import 'treinos_hub_view.dart';

typedef TreinosDestaqueTexto =
    ({
      String eyebrow,
      String titulo,
      String detalhe,
      String? prazo,
      String? cta,
      double? progresso,
    });

TreinosDestaqueTexto treinosDestaqueTexto(
  S s,
  TreinosDestaque d, {
  required DateTime hoje,
}) {
  final t = d.treino;
  final prazo = alunoPrazoTexto(
    s,
    TreinoAtribuicaoPrazo.parseIsoDate(t.dataFim),
    hoje: hoje,
  );
  return switch (d.tipo) {
    TreinosDestaqueTipo.emAndamento => _emAndamento(s, d, prazo),
    TreinosDestaqueTipo.concluidoHoje => (
      eyebrow: s.treinosDestaqueConcluidoHoje,
      titulo: t.treinoNome,
      detalhe: switch (d.duracao) {
        final Duration dur => treinosDuracaoTexto(s, dur),
        null => _semDuracao(s, t.exerciciosConcluidos ?? 0),
      },
      prazo: null,
      cta: s.treinosVerTreinoCta,
      progresso: null,
    ),
    TreinosDestaqueTipo.proximo => (
      eyebrow: s.treinosDestaqueProximo,
      titulo: t.treinoNome,
      detalhe: s.treinosExercicios(t.totalExercicios),
      prazo: prazo,
      cta: s.treinosIniciarCta,
      progresso: null,
    ),
    TreinosDestaqueTipo.emPreparacao => (
      eyebrow: s.treinosDestaqueEmPreparacao,
      titulo: t.treinoNome,
      detalhe: s.treinosEmPreparacaoDetalhe,
      prazo: null,
      cta: null,
      progresso: null,
    ),
  };
}

/// "N de M" só com os dois números do servidor; senão só "M exercícios".
TreinosDestaqueTexto _emAndamento(S s, TreinosDestaque d, String? prazo) {
  final total = d.treino.totalExercicios;
  final feitos = d.exerciciosFeitos;
  final comProgresso = feitos != null && total > 0;
  return (
    eyebrow: s.treinosDestaqueEmAndamento,
    titulo: d.treino.treinoNome,
    detalhe:
        comProgresso
            ? s.treinosExerciciosProgresso(feitos.clamp(0, total), total)
            : s.treinosExercicios(total),
    prazo: prazo,
    cta: s.treinosContinuarCta,
    progresso: comProgresso ? feitos.clamp(0, total) / total : null,
  );
}

/// Linha do plano: contagem ou "Em preparação" (status em texto, não só cor).
String treinosPlanoDetalhe(S s, ExecucaoTreino t) =>
    isTreinoAguardandoLiberacao(t)
        ? s.treinosDestaqueEmPreparacao
        : s.treinosExercicios(t.totalExercicios);

/// Detalhe do último treino: duração real; senão exercícios feitos; senão
/// registro sem séries ("Já fiz").
String treinosRecenteDetalhe(S s, TreinoRecente r) => switch (r.duracao) {
  final Duration d => treinosDuracaoTexto(s, d),
  null => _semDuracao(s, r.exerciciosConcluidos),
};

String _semDuracao(S s, int concluidos) =>
    concluidos > 0 ? s.treinosExerciciosFeitos(concluidos) : s.treinosSemSeries;

String treinosDiaTexto(S s, DateTime quando, {required DateTime hoje}) =>
    switch (alunoDiasAte(hoje, quando)) {
      0 => s.treinosDiaHoje,
      1 => s.treinosDiaOntem,
      _ => s.treinosDiaData(quando),
    };

String treinosDuracaoTexto(S s, Duration d) {
  final h = d.inHours;
  final min = d.inMinutes.remainder(60);
  if (h == 0) return s.treinosDuracaoMinutos(min);
  if (min == 0) return s.treinosDuracaoHoras(h);
  return s.treinosDuracaoHorasMinutos(h, min);
}

/// Leitura única do destaque: "Próximo treino: Treino A, 6 exercícios, Até 23 de out.".
String treinosDestaqueSemantics(TreinosDestaqueTexto t) => [
  '${t.eyebrow}: ${t.titulo}',
  t.detalhe,
  if (t.prazo case final prazo?) prazo,
].join(', ');
