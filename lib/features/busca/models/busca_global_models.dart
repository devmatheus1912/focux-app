/// Modelos da busca global — parse na borda API → UI tipada.
class BuscaItem {
  const BuscaItem({
    required this.id,
    required this.titulo,
    this.subtitulo,
    required this.tipo,
    required this.url,
  });

  final int id;
  final String titulo;
  final String? subtitulo;
  final String tipo;
  final String url;

  factory BuscaItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return BuscaItem(
      id: idRaw is num ? idRaw.toInt() : 0,
      titulo: '${json['titulo'] ?? json['nome'] ?? ''}',
      subtitulo: json['subtitulo'] as String?,
      tipo: '${json['tipo'] ?? ''}',
      url: '${json['url'] ?? json['link'] ?? ''}',
    );
  }
}

class BuscaGlobalResult {
  const BuscaGlobalResult({
    required this.alunos,
    required this.treinos,
    required this.cobrancas,
  });

  const BuscaGlobalResult.empty()
    : alunos = const [],
      treinos = const [],
      cobrancas = const [];

  final List<BuscaItem> alunos;
  final List<BuscaItem> treinos;
  final List<BuscaItem> cobrancas;

  factory BuscaGlobalResult.fromJson(Map<String, dynamic> json) =>
      BuscaGlobalResult(
        alunos: _parseItems(json['alunos']),
        treinos: _parseItems(json['treinos']),
        cobrancas: _parseItems(json['cobrancas']),
      );

  static List<BuscaItem> _parseItems(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => BuscaItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  bool get isEmpty => alunos.isEmpty && treinos.isEmpty && cobrancas.isEmpty;
  int get totalCount => alunos.length + treinos.length + cobrancas.length;
}

enum BuscaTipo { todos, aluno, treino, cobranca }

extension BuscaTipoExt on BuscaTipo {
  String get label => switch (this) {
    BuscaTipo.todos => 'Todos',
    BuscaTipo.aluno => 'Alunos',
    BuscaTipo.treino => 'Treinos',
    BuscaTipo.cobranca => 'Cobranças',
  };
}
