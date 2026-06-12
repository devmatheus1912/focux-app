import 'dart:convert';

/// Linha de aluno na pré-visualização da migração mágica.
class MigracaoAlunoLinha {
  const MigracaoAlunoLinha({
    required this.nome,
    this.email,
    this.telefone,
    this.objetivo,
    this.observacao,
    this.duplicado = false,
    this.raw = const {},
  });

  final String nome;
  final String? email;
  final String? telefone;
  final String? objetivo;
  final String? observacao;
  final bool duplicado;
  final Map<String, dynamic> raw;

  factory MigracaoAlunoLinha.fromJson(Map<String, dynamic> json) {
    return MigracaoAlunoLinha(
      nome: (json['nome'] ?? json['name'] ?? '').toString().trim(),
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString(),
      objetivo: json['objetivo']?.toString(),
      observacao: json['observacao']?.toString(),
      duplicado: json['duplicado'] == true || json['duplicate'] == true,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
    if (objetivo != null && objetivo!.isNotEmpty) 'objetivo': objetivo,
    if (observacao != null && observacao!.isNotEmpty) 'observacao': observacao,
    if (duplicado) 'duplicado': true,
  };

  MigracaoAlunoLinha copyWith({
    String? nome,
    String? email,
    String? telefone,
    String? objetivo,
    String? observacao,
    bool? duplicado,
  }) {
    final next = toJson()
      ..['nome'] = nome ?? this.nome
      ..['email'] = email ?? this.email
      ..['telefone'] = telefone ?? this.telefone
      ..['objetivo'] = objetivo ?? this.objetivo
      ..['observacao'] = observacao ?? this.observacao
      ..['duplicado'] = duplicado ?? this.duplicado;
    return MigracaoAlunoLinha.fromJson(next);
  }

  static List<MigracaoAlunoLinha>? parseLista(dynamic data) {
    if (data is! List) return null;
    return data
        .whereType<Map>()
        .map((item) => MigracaoAlunoLinha.fromJson(Map<String, dynamic>.from(item)))
        .where((row) => row.nome.isNotEmpty)
        .toList();
  }

  static List<MigracaoAlunoLinha>? parseResultado(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      try {
        return parseResultado(jsonDecode(data));
      } catch (_) {
        return null;
      }
    }
    if (data is Map && data.containsKey('alunos')) {
      final lista = data['alunos'];
      if (lista is List) return parseLista(lista);
    }
    if (data is List) return parseLista(data);
    return null;
  }

  static List<MigracaoAlunoLinha> fromPreviewResponse(dynamic data) {
    if (data is! Map || data['alunos'] is! List) return const [];
    return parseLista(data['alunos']) ?? const [];
  }
}
