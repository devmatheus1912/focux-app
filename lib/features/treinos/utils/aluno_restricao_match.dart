import '../../anamnese/data/anamnese_repository.dart';
import '../../exercicios/data/exercicio_repository.dart';
import 'exercicio_texto.dart';

/// Regiões que a anamnese e as contraindicações costumam citar. O casamento é
/// por palavra, não por regra clínica: serve de aviso, nunca de bloqueio.
enum RegiaoCorpo {
  joelho('joelho', ['joelho', 'patela', 'menisco', 'ligamento cruzado']),
  ombro('ombro', ['ombro', 'manguito']),
  lombar('lombar', ['lombar', 'coluna', 'hernia', 'ciatic']),
  punho('punho', ['punho', 'carpo']),
  cotovelo('cotovelo', ['cotovelo', 'epicondil']),
  quadril('quadril', ['quadril', 'bacia']),
  tornozelo('tornozelo', ['tornozelo']),
  pescoco('pescoço', ['pescoco', 'cervical']);

  const RegiaoCorpo(this.rotulo, this.palavras);

  final String rotulo;
  final List<String> palavras;
}

/// Regiões citadas em um texto livre (sem acento, sem caixa).
Set<RegiaoCorpo> regioesCitadas(String? texto) {
  final t = semAcento(texto);
  if (t.trim().isEmpty) return const {};
  return {
    for (final regiao in RegiaoCorpo.values)
      if (regiao.palavras.any(t.contains)) regiao,
  };
}

/// Regiões que a anamnese do aluno cita em lesões, dores e cirurgias.
Set<RegiaoCorpo> regioesDaAnamnese(Anamnese? anamnese) {
  if (anamnese == null) return const {};
  return regioesCitadas(
    [anamnese.lesoes, anamnese.doresCronicas, anamnese.cirurgias]
        .whereType<String>()
        .join(' '),
  );
}

/// Há algo a avisar: lesão, dor crônica ou problema ósseo/articular no PAR-Q.
bool anamneseTemRestricao(Anamnese? anamnese) {
  if (anamnese == null) return false;
  bool preenchido(String? v) => v != null && v.trim().isNotEmpty;
  return preenchido(anamnese.lesoes) ||
      preenchido(anamnese.doresCronicas) ||
      anamnese.parqProblemaOsseoArticular == true ||
      anamnese.parqPositivo == true;
}

/// Regiões em comum entre o aluno e as **contraindicações** do exercício.
/// Só as contraindicações: "erros comuns" cita a lombar e o joelho de quase
/// todo exercício e marcaria tudo.
Set<RegiaoCorpo> regioesEmComum(Set<RegiaoCorpo> aluno, Exercicio exercicio) {
  if (aluno.isEmpty) return const {};
  return regioesCitadas(exercicio.contraindicacoes).intersection(aluno);
}

/// "joelho · lombar", para a faixa do topo.
String resumoRegioes(Set<RegiaoCorpo> regioes) =>
    regioes.map((r) => r.rotulo).join(' · ');
