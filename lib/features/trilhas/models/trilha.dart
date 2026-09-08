/// Trilha de progresso do aluno — parse na borda API.
class MarcoModel {
  const MarcoModel({
    required this.id,
    required this.titulo,
    required this.ordem,
    required this.concluido,
  });

  final int id;
  final String titulo;
  final int ordem;
  final bool concluido;

  factory MarcoModel.fromJson(Map<String, dynamic> json) => MarcoModel(
    id: json['id'] as int,
    titulo: (json['titulo'] ?? '').toString(),
    ordem: json['ordem'] as int? ?? 0,
    concluido: json['concluido'] as bool? ?? false,
  );
}

class TrilhaModel {
  const TrilhaModel({
    required this.id,
    required this.alunoId,
    required this.titulo,
    required this.metaTipo,
    required this.valorAtual,
    required this.percentualConclusao,
    required this.concluida,
    required this.marcos,
    this.descricao,
    this.metaValor,
    this.dataInicio,
    this.dataFim,
  });

  final int id;
  final int alunoId;
  final String titulo;
  final String? descricao;
  final String metaTipo;
  final double? metaValor;
  final double valorAtual;
  final double percentualConclusao;
  final bool concluida;
  final String? dataInicio;
  final String? dataFim;
  final List<MarcoModel> marcos;

  factory TrilhaModel.fromJson(Map<String, dynamic> json) => TrilhaModel(
    id: json['id'] as int,
    alunoId: json['alunoId'] as int,
    titulo: (json['titulo'] ?? '').toString(),
    descricao: json['descricao']?.toString(),
    metaTipo: (json['metaTipo'] ?? 'TREINOS').toString(),
    metaValor:
        json['metaValor'] != null ? (json['metaValor'] as num).toDouble() : null,
    valorAtual: (json['valorAtual'] as num?)?.toDouble() ?? 0,
    percentualConclusao: (json['percentualConclusao'] as num?)?.toDouble() ?? 0,
    concluida: json['concluida'] as bool? ?? false,
    dataInicio: json['dataInicio']?.toString(),
    dataFim: json['dataFim']?.toString(),
    marcos:
        (json['marcos'] as List? ?? [])
            .whereType<Map>()
            .map((item) => MarcoModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
  );

  static List<TrilhaModel> parseList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => TrilhaModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class NovaTrilhaRequest {
  const NovaTrilhaRequest({
    required this.alunoId,
    required this.titulo,
    required this.metaTipo,
    this.descricao,
    this.metaValor,
    this.dataFim,
    this.marcos,
  });

  final int alunoId;
  final String titulo;
  final String? descricao;
  final String metaTipo;
  final double? metaValor;
  final String? dataFim;
  final List<String>? marcos;

  Map<String, dynamic> toJson() => {
    'alunoId': alunoId,
    'titulo': titulo,
    'metaTipo': metaTipo,
    if (descricao != null) 'descricao': descricao,
    if (metaValor != null) 'metaValor': metaValor,
    if (dataFim != null) 'dataFim': dataFim,
    if (marcos != null && marcos!.isNotEmpty) 'marcos': marcos,
  };
}
