import '../../../l10n/app_localizations.dart';
import '../data/aluno_destaque_exercicio.dart';
import '../data/dashboard_repository.dart';
import 'aluno_home_texts.dart';
import 'aluno_home_week.dart';

/// Uma linha de ritmo: sobrancelha, número e uma frase. Null quando não há fato.
class AlunoRitmoLinha {
  const AlunoRitmoLinha({
    required this.sobrancelha,
    required this.titulo,
    this.frase,
  });

  final String sobrancelha;
  final String titulo;
  final String? frase;
}

/// Ritmo da aba Treinos a partir do agregado da Home.
AlunoRitmoLinha? alunoRitmoDaSemana(S s, AlunoDashboardHomeBundle home) {
  return alunoSemanaLinha(
    s,
    buildAlunoWeekSummary(
      concluidosSemanaIso: home.concluidosSemanaIso,
      frequenciaDias: home.frequenciaDias,
      streakAtual: home.streakAtual,
      volumeSemanaKg: home.volumeSemanaKg,
    ),
  );
}

/// "2 de 3" na aba Treinos. A sequência e o volume cabem na frase.
AlunoRitmoLinha? alunoSemanaLinha(S s, AlunoWeekSummary semana) {
  if (semana.isEmpty || semana.feitos == null) return null;
  final partes = <String>[
    if (semana.streakSemanas > 0)
      alunoInicialMaiuscula(s.alunoSemanaFraseSequencia(semana.streakSemanas)),
    if (semana.volumeKg case final volume?) alunoVolumeTexto(s, volume),
  ];
  return AlunoRitmoLinha(
    sobrancelha: s.alunoSemanaTitulo,
    titulo: alunoTreinosSemanaValor(s, semana),
    frase: partes.isEmpty ? null : partes.join(' · '),
  );
}

/// Ganho do exercício no histórico. Sem curva, o recorde do mês ainda entra.
AlunoRitmoLinha? alunoEvolucaoLinha(
  S s, {
  required AlunoDestaqueExercicio? destaque,
  required int recordesMes,
  String? ultimaData,
}) {
  final rodape = alunoRecordesRodape(
    s,
    recordesMes: recordesMes,
    ultimaData: ultimaData,
  );
  final d = destaque;
  if (d == null) {
    if (rodape == null) return null;
    return AlunoRitmoLinha(sobrancelha: s.alunoEvolucaoTitulo, titulo: rodape);
  }
  final frase = d.temCurva
      ? s.alunoEvolucaoDeltaEmSemanas(
          alunoForcaDeltaTexto(s, d.deltaPercent),
          d.semanas,
        )
      : rodape;
  return AlunoRitmoLinha(
    sobrancelha: alunoInicialMaiuscula(d.nome),
    titulo: d.temCurva
        ? s.alunoEvolucaoCargaDeAte(d.inicialKg, d.atualKg)
        : s.alunoEvolucaoCargaKg(d.atualKg),
    frase: frase,
  );
}
