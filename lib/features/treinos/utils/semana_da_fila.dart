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

SemanaMontada filaDaSemana(List<DiaDaSemana> dias) {
  final itens = <ItemDaFila>[];
  final avisos = <int>[];
  var viuSessao = false;
  for (final dia in dias) {
    final nomes = dia.sessoes
        .map((s) => s.nome.trim())
        .where((nome) => nome.isNotEmpty)
        .toList();
    if (nomes.isNotEmpty && !dia.descanso) {
      viuSessao = true;
      for (final nome in nomes) {
        itens.add(ItemDaFila.treino(nome, dia.dia));
      }
      continue;
    }
    avisos.add(dia.dia);
    if (viuSessao && (itens.isEmpty || !itens.last.descanso)) {
      itens.add(const ItemDaFila.descanso());
    }
  }
  return SemanaMontada(itens: itens, avisos: avisos);
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

/// Resumo da semana numa linha: "Seg Peito · Ter Costas · Qua descanso…".
/// Vazio quando a ficha não tem sessão.
String resumoDaSemana(
  RotinaFila fila, {
  required List<String> nomesDosDias,
  required String palavraDescanso,
}) {
  final dias = semanaDaFila(fila);
  if (dias.every((dia) => dia.sessoes.isEmpty)) return '';
  return [
    for (var i = 0; i < dias.length; i++)
      () {
        final nomes = dias[i].sessoes
            .map((sessao) => sessao.nome.trim())
            .where((nome) => nome.isNotEmpty)
            .toList();
        return nomes.isEmpty
            ? '${nomesDosDias[i]} ${palavraDescanso.toLowerCase()}'
            : '${nomesDosDias[i]} ${nomes.join(' + ')}';
      }(),
  ].join(' · ');
}
