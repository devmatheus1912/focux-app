/// Um dia do modelo: uma sessão ou um descanso.
class FichaModeloItem {
  const FichaModeloItem({
    required this.descanso,
    this.treinoId,
    this.nome = '',
    this.diaSemana,
    this.exerciciosCount = 0,
  });

  final bool descanso;
  final int? treinoId;
  final String nome;
  final int? diaSemana;
  final int exerciciosCount;

  factory FichaModeloItem.fromJson(Map<String, dynamic> json) {
    final descanso = (json['tipo'] as String? ?? '').toUpperCase() == 'DESCANSO';
    return FichaModeloItem(
      descanso: descanso,
      treinoId: (json['treinoId'] as num?)?.toInt(),
      nome: json['nome'] as String? ?? '',
      diaSemana: (json['diaSemana'] as num?)?.toInt(),
      exerciciosCount: (json['exerciciosCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Modelo de ficha: uma semana inteira ("Hipertrofia 4 dias").
class FichaModelo {
  const FichaModelo({
    required this.id,
    required this.nome,
    this.avisoDias = const [],
    this.itens = const [],
  });

  final int id;
  final String nome;
  final List<int> avisoDias;
  final List<FichaModeloItem> itens;

  List<FichaModeloItem> get sessoes =>
      itens.where((item) => !item.descanso).toList(growable: false);

  int get totalExercicios =>
      sessoes.fold(0, (soma, sessao) => soma + sessao.exerciciosCount);

  /// Todas as sessões já têm exercício.
  bool get pronto =>
      sessoes.isNotEmpty && sessoes.every((s) => s.exerciciosCount > 0);

  /// "A · B · C · D": a letra de cada sessão, na ordem. Sessão sem letra
  /// ("Peito") usa o nome inteiro.
  String get resumoDasSessoes => sessoes
      .map((s) {
        final match = RegExp(r'^Treino ([A-Za-z])$').firstMatch(s.nome.trim());
        return match?.group(1)?.toUpperCase() ?? s.nome;
      })
      .join(' · ');

  factory FichaModelo.fromJson(Map<String, dynamic> json) {
    return FichaModelo(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      avisoDias: (json['avisoDias'] as List? ?? const [])
          .map((dia) => (dia as num).toInt())
          .toList(growable: false),
      itens: (json['itens'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => FichaModeloItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}
