import '../models/rotina_fila.dart';
import 'divisao_catalogo.dart';

class SessaoDaSemana {
  const SessaoDaSemana({
    this.treinoId,
    required this.nome,
    this.exerciciosCount,
  });

  final int? treinoId;
  final String nome;

  /// Null quando o backend não informou; 0 é sessão vazia.
  final int? exerciciosCount;
}

class DiaDaSemana {
  const DiaDaSemana({
    required this.dia,
    this.sessoes = const [],
    this.descanso = false,
    this.segueSequencia = false,
  });

  final int dia;
  final List<SessaoDaSemana> sessoes;
  final bool descanso;

  /// Dia de treino sem sessão própria: o aluno faz a próxima da fila (rodízio).
  final bool segueSequencia;

  DiaDaSemana copyWith({
    List<SessaoDaSemana>? sessoes,
    bool? descanso,
    bool? segueSequencia,
  }) => DiaDaSemana(
    dia: dia,
    sessoes: sessoes ?? this.sessoes,
    descanso: descanso ?? this.descanso,
    segueSequencia: segueSequencia ?? this.segueSequencia,
  );
}

class ItemDaFila {
  const ItemDaFila.treino(this.nome, this.dia) : descanso = false;
  const ItemDaFila.descanso() : descanso = true, nome = null, dia = null;

  final bool descanso;
  final String? nome;
  final int? dia;
}

class SemanaMontada {
  const SemanaMontada({required this.itens, required this.avisos});

  final List<ItemDaFila> itens;
  final List<int> avisos;
}

List<DiaDaSemana> semanaDaFila(RotinaFila fila) {
  final dias = List.generate(7, (i) => DiaDaSemana(dia: i + 1));
  final porDia = <int, List<SessaoDaSemana>>{};
  var cursor = 1;
  for (final item in fila.itens) {
    if (item.descanso) continue;
    final dia = item.diaSemana;
    final destino = (dia != null && dia >= 1 && dia <= 7) ? dia : cursor++;
    if (cursor > 8) cursor = 8;
    porDia.putIfAbsent(destino, () => []).add(
      SessaoDaSemana(
        treinoId: item.treinoId,
        nome: item.nome ?? '',
        exerciciosCount: item.exerciciosCount,
      ),
    );
  }
  // Só a ficha gravada pela semana (toda sessão com dia) tem dia que segue a sequência.
  // Fila antiga, montada por "atribuir", não tem dia: o dia vazio fica como antes.
  final pelaSemana = fila.itens.every((item) => item.descanso || item.diaSemana != null);
  return [
    for (final dia in dias)
      if ((porDia[dia.dia] ?? const []).isNotEmpty)
        DiaDaSemana(dia: dia.dia, sessoes: porDia[dia.dia]!)
      else if (fila.diasAviso.contains(dia.dia) || porDia.isEmpty)
        DiaDaSemana(dia: dia.dia, descanso: true)
      else if (pelaSemana)
        DiaDaSemana(dia: dia.dia, segueSequencia: true)
      else
        DiaDaSemana(dia: dia.dia),
  ];
}

/// Dias de treino padrão por frequência (ponto de partida; o personal muda depois).
const diasPorFrequencia = {
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 3, 4, 5],
  6: [1, 2, 3, 4, 5, 6],
  7: [1, 2, 3, 4, 5, 6, 7],
};

/// Semana nova com Treino A, B, C… nos dias padrão da frequência escolhida.
/// Os outros dias viram descanso. Fora de 2 a 7, devolve a semana vazia.
List<DiaDaSemana> semanaPorFrequencia(int diasPorSemana) =>
    semanaPorDivisao(
      diasPorFrequencia[diasPorSemana] ?? const <int>[],
      umaPorDia(diasPorSemana),
    );

/// Sessões da [divisao] nos primeiros [diasDeTreino] (1 a 7, em qualquer ordem).
/// Dias de treino que sobram seguem a sequência; os outros são descanso.
List<DiaDaSemana> semanaPorDivisao(List<int> diasDeTreino, Divisao divisao) {
  final ordem = [...diasDeTreino]..sort();
  return [
    for (var dia = 1; dia <= 7; dia++)
      switch (ordem.indexOf(dia)) {
        -1 => DiaDaSemana(dia: dia, descanso: true),
        final i when i < divisao.letras => DiaDaSemana(
          dia: dia,
          sessoes: [SessaoDaSemana(nome: divisao.sessoes[i])],
        ),
        _ => DiaDaSemana(dia: dia, segueSequencia: true),
      },
  ];
}

/// Semana toda de descanso: "Recomeçar ficha".
List<DiaDaSemana> semanaVazia() => [
  for (var dia = 1; dia <= 7; dia++) DiaDaSemana(dia: dia, descanso: true),
];

/// Move as sessões de [de] para [para]; se [para] já tem sessões, elas trocam
/// de lugar. O dia de origem herda o que o destino era (descanso ou segue a sequência).
List<DiaDaSemana> moverDia(
  List<DiaDaSemana> semana, {
  required int de,
  required int para,
}) {
  if (de == para) return semana;
  final origem = semana.firstWhere((d) => d.dia == de);
  final destino = semana.firstWhere((d) => d.dia == para);
  return [
    for (final d in semana)
      if (d.dia == de)
        d.copyWith(
          sessoes: destino.sessoes,
          descanso: destino.sessoes.isEmpty && !destino.segueSequencia,
          segueSequencia: destino.sessoes.isEmpty && destino.segueSequencia,
        )
      else if (d.dia == para)
        d.copyWith(sessoes: origem.sessoes, descanso: false, segueSequencia: false)
      else
        d,
  ];
}

/// Descanso vira dia que segue a sequência; dia sem sessão que segue vira descanso.
/// Dia com sessão não muda (tirar as sessões é "Marcar descanso").
List<DiaDaSemana> alternarTreinoDescanso(List<DiaDaSemana> semana, int dia) => [
  for (final d in semana)
    if (d.dia != dia || d.sessoes.isNotEmpty)
      d
    else if (d.segueSequencia)
      DiaDaSemana(dia: d.dia, descanso: true)
    else
      DiaDaSemana(dia: d.dia, segueSequencia: true),
];

/// Acrescenta [sessao] ao fim do dia [dia] (cópia de uma sessão, por exemplo).
List<DiaDaSemana> comSessaoNoDia(
  List<DiaDaSemana> semana, {
  required int dia,
  required SessaoDaSemana sessao,
}) => [
  for (final d in semana)
    d.dia == dia
        ? d.copyWith(sessoes: [...d.sessoes, sessao], descanso: false, segueSequencia: false)
        : d,
];

/// Quantos dias treinam, quantas sessões a ficha tem e quantas já têm exercício.
/// Contagem desconhecida (backend antigo) conta como pronta, para não avisar à toa.
class EstadoDaFicha {
  const EstadoDaFicha({
    required this.dias,
    required this.sessoes,
    required this.prontas,
  });

  final int dias;
  final int sessoes;
  final int prontas;

  int get incompletas => sessoes - prontas;
  bool get vazia => sessoes == 0;
  bool get completa => sessoes > 0 && incompletas == 0;
}

EstadoDaFicha estadoDaFicha(List<DiaDaSemana> semana) {
  var dias = 0;
  var sessoes = 0;
  var prontas = 0;
  for (final dia in semana) {
    if (dia.segueSequencia && dia.sessoes.isEmpty) dias++;
    if (dia.sessoes.isEmpty) continue;
    dias++;
    for (final sessao in dia.sessoes) {
      sessoes++;
      if ((sessao.exerciciosCount ?? 1) > 0) prontas++;
    }
  }
  return EstadoDaFicha(dias: dias, sessoes: sessoes, prontas: prontas);
}

/// Resultado de "Mudar divisão": a semana nova e as sessões que saem dela.
class DivisaoTrocada {
  const DivisaoTrocada({required this.semana, required this.saem});

  final List<DiaDaSemana> semana;
  final List<SessaoDaSemana> saem;
}

/// Põe a [nova] semana (dias e letras escolhidos) no lugar da [atual] sem
/// perder exercício: a 1ª sessão nova recebe a 1ª sessão de hoje (A com A),
/// e assim por diante, mantendo treino e nome. Letras novas nascem vazias;
/// as sessões de hoje que sobram saem.
DivisaoTrocada trocarDivisao(List<DiaDaSemana> atual, List<DiaDaSemana> nova) {
  final hoje = [
    for (final d in atual)
      for (final s in d.sessoes) s,
  ];
  var usadas = 0;
  final semana = <DiaDaSemana>[];
  for (final d in nova) {
    if (d.sessoes.isEmpty) {
      semana.add(d);
      continue;
    }
    final sessoes = <SessaoDaSemana>[];
    for (final nova in d.sessoes) {
      sessoes.add(usadas < hoje.length ? hoje[usadas] : nova);
      usadas++;
    }
    semana.add(d.copyWith(sessoes: sessoes));
  }
  return DivisaoTrocada(
    semana: semana,
    saem: usadas < hoje.length ? hoje.sublist(usadas) : const [],
  );
}
