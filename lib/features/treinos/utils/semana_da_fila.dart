import '../models/rotina_fila.dart';

class SessaoDaSemana {
  const SessaoDaSemana({this.treinoId, required this.nome});

  final int? treinoId;
  final String nome;
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
      SessaoDaSemana(treinoId: item.treinoId, nome: item.nome ?? ''),
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
