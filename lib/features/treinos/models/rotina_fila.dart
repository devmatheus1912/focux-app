enum RotinaItemTipo { treino, descanso }

class RotinaItem {
  const RotinaItem({
    required this.id,
    required this.tipo,
    this.treinoId,
    this.nome,
  });

  final int id;
  final RotinaItemTipo tipo;
  final int? treinoId;
  final String? nome;

  bool get descanso => tipo == RotinaItemTipo.descanso;

  String rotulo(String palavraDescanso) =>
      descanso ? palavraDescanso : (nome?.trim().isNotEmpty == true ? nome!.trim() : '');

  factory RotinaItem.fromJson(Map<String, dynamic> json) {
    final tipoRaw = (json['tipo'] as String? ?? '').toUpperCase();
    return RotinaItem(
      id: (json['id'] as num).toInt(),
      tipo: tipoRaw == 'DESCANSO' ? RotinaItemTipo.descanso : RotinaItemTipo.treino,
      treinoId: (json['treinoId'] as num?)?.toInt(),
      nome: json['nome'] as String?,
    );
  }
}

/// Fila que a Home devolve e que a tela do personal edita.
class RotinaFila {
  const RotinaFila({
    this.itens = const [],
    this.diasAviso = const {},
    this.sessaoAbertaTreinoId,
    this.ultimoTreinoId,
    this.concluiuHoje = false,
  });

  static const vazia = RotinaFila();

  final List<RotinaItem> itens;
  final Set<int> diasAviso;
  final int? sessaoAbertaTreinoId;
  final int? ultimoTreinoId;
  final bool concluiuHoje;

  bool get temTreino => itens.any((item) => !item.descanso);

  String linha(String palavraDescanso) => itens
      .map((item) => item.rotulo(palavraDescanso))
      .where((nome) => nome.isNotEmpty)
      .join(', ');

  factory RotinaFila.fromJson(Object? raw) {
    if (raw is! Map) return RotinaFila.vazia;
    final json = Map<String, dynamic>.from(raw);
    final itens = (json['itens'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => RotinaItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final dias = (json['diasAviso'] as List? ?? const [])
        .map((dia) => dia is num ? dia.toInt() : int.tryParse('$dia'))
        .whereType<int>()
        .where((dia) => dia >= 1 && dia <= 7)
        .toSet();
    return RotinaFila(
      itens: itens,
      diasAviso: dias,
      sessaoAbertaTreinoId: (json['sessaoAbertaTreinoId'] as num?)?.toInt(),
      ultimoTreinoId: (json['ultimoTreinoId'] as num?)?.toInt(),
      concluiuHoje: json['concluiuHoje'] == true,
    );
  }
}
