class PlanoSucesso {
  final int id;
  final int personalId;
  final String objetivoPrincipal;
  final String status;
  final DateTime dataInicio;
  final DateTime? proximaRevisao;
  final List<MarcoSucesso> marcos;

  PlanoSucesso({
    required this.id,
    required this.personalId,
    required this.objetivoPrincipal,
    required this.status,
    required this.dataInicio,
    required this.proximaRevisao,
    required this.marcos,
  });

  factory PlanoSucesso.fromJson(Map<String, dynamic> json) => PlanoSucesso(
    id: json['id'],
    personalId: json['personalId'],
    objetivoPrincipal: json['objetivoPrincipal'],
    status: json['status'] as String? ?? 'ATIVO',
    dataInicio: DateTime.parse(json['dataInicio'] as String),
    proximaRevisao: _date(json['proximaRevisao']),
    marcos:
        (json['marcos'] as List).map((m) => MarcoSucesso.fromJson(m)).toList(),
  );
}

class MarcoSucesso {
  final int id;
  final String titulo;
  final String? descricao;
  final bool atingido;
  final DateTime? dataAtingido;

  MarcoSucesso({
    required this.id,
    required this.titulo,
    required this.atingido,
    this.descricao,
    this.dataAtingido,
  });

  factory MarcoSucesso.fromJson(Map<String, dynamic> json) => MarcoSucesso(
    id: json['id'],
    titulo: json['titulo'],
    descricao: json['descricao'] as String?,
    atingido: json['atingido'] as bool? ?? false,
    dataAtingido: _date(json['dataAtingido']),
  );
}

DateTime? _date(dynamic raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw);
}
