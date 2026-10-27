import '../models/rotina_fila.dart';

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
  });

  final int dia;
  final List<SessaoDaSemana> sessoes;
  final bool descanso;

  DiaDaSemana copyWith({
    List<SessaoDaSemana>? sessoes,
    bool? descanso,
  }) => DiaDaSemana(
    dia: dia,
    sessoes: sessoes ?? this.sessoes,
    descanso: descanso ?? this.descanso,
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
  return [
    for (final dia in dias)
      DiaDaSemana(
        dia: dia.dia,
        sessoes: porDia[dia.dia] ?? const [],
        descanso: (porDia[dia.dia] ?? const []).isEmpty &&
            (fila.diasAviso.contains(dia.dia) || porDia.isEmpty),
      ),
  ];
}

const _diasPorFrequencia = {
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 3, 4, 5],
  6: [1, 2, 3, 4, 5, 6],
  7: [1, 2, 3, 4, 5, 6, 7],
};

/// Semana nova com Treino A, B, C… nos dias padrão da frequência escolhida.
/// Os outros dias viram descanso. Fora de 2 a 7, devolve a semana vazia.
List<DiaDaSemana> semanaPorFrequencia(int diasPorSemana) {
  final dias = _diasPorFrequencia[diasPorSemana] ?? const <int>[];
  return [
    for (var dia = 1; dia <= 7; dia++)
      DiaDaSemana(
        dia: dia,
        sessoes: dias.contains(dia)
            ? [
                SessaoDaSemana(
                  nome: 'Treino ${String.fromCharCode(65 + dias.indexOf(dia))}',
                ),
              ]
            : const [],
        descanso: !dias.contains(dia),
      ),
  ];
}

/// Semana toda de descanso: "Recomeçar ficha".
List<DiaDaSemana> semanaVazia() => [
  for (var dia = 1; dia <= 7; dia++) DiaDaSemana(dia: dia, descanso: true),
];

/// Move as sessões de [de] para [para]; se [para] já tem sessões, elas trocam
/// de lugar. O dia que fica sem sessão vira descanso.
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
          descanso: destino.sessoes.isEmpty,
        )
      else if (d.dia == para)
        d.copyWith(sessoes: origem.sessoes, descanso: false)
      else
        d,
  ];
}

/// Acrescenta [sessao] ao fim do dia [dia] (cópia de uma sessão, por exemplo).
List<DiaDaSemana> comSessaoNoDia(
  List<DiaDaSemana> semana, {
  required int dia,
  required SessaoDaSemana sessao,
}) => [
  for (final d in semana)
    d.dia == dia
        ? d.copyWith(sessoes: [...d.sessoes, sessao], descanso: false)
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
    if (dia.sessoes.isEmpty) continue;
    dias++;
    for (final sessao in dia.sessoes) {
      sessoes++;
      if ((sessao.exerciciosCount ?? 1) > 0) prontas++;
    }
  }
  return EstadoDaFicha(dias: dias, sessoes: sessoes, prontas: prontas);
}
