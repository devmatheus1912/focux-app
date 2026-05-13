class PlanoSucesso {
  final int id;
  final int personalId;
  final String objetivoPrincipal;
  final String status;
  final DateTime dataInicio;
  final DateTime proximaRevisao;
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
    status: json['status'],
    dataInicio: DateTime.parse(json['dataInicio']),
    proximaRevisao:
        json['proximaRevisao'] != null
            ? DateTime.parse(json['proximaRevisao'])
            : DateTime.now(),
    marcos:
        (json['marcos'] as List).map((m) => MarcoSucesso.fromJson(m)).toList(),
  );
}

class MarcoSucesso {
  final int id;
  final String titulo;
  final bool atingido;

  MarcoSucesso({
    required this.id,
    required this.titulo,
    required this.atingido,
  });

  factory MarcoSucesso.fromJson(Map<String, dynamic> json) => MarcoSucesso(
    id: json['id'],
    titulo: json['titulo'],
    atingido: json['atingido'],
  );
}
