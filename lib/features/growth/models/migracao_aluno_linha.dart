import 'dart:convert';

import '../utils/migracao_linha_classifier.dart';

/// Linha de aluno na pré-visualização da migração mágica.
class MigracaoAlunoLinha {
  const MigracaoAlunoLinha({
    required this.nome,
    this.email,
    this.telefone,
    this.objetivo,
    this.observacao,
    this.duplicado = false,
    this.status = MigracaoLinhaStatus.valido,
    bool? selecionado,
    this.raw = const {},
  }) : selecionado = selecionado ?? status == MigracaoLinhaStatus.valido;

  final String nome;
  final String? email;
  final String? telefone;
  final String? objetivo;
  final String? observacao;
  final bool duplicado;
  final MigracaoLinhaStatus status;

  /// Entra no salvamento. Duvidosos começam desmarcados.
  final bool selecionado;
  final Map<String, dynamic> raw;

  bool get entraNoSalvamento => selecionado && !duplicado;

  factory MigracaoAlunoLinha.fromJson(Map<String, dynamic> json) {
    return MigracaoAlunoLinha(
      nome: (json['nome'] ?? json['name'] ?? '').toString().trim(),
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString(),
      objetivo: json['objetivo']?.toString(),
      observacao: json['observacao']?.toString(),
      duplicado: json['duplicado'] == true || json['duplicate'] == true,
      status: migracaoLinhaStatusFromApi(json['status']),
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
    MigracaoLinhaStatus? status,
    bool? selecionado,
  }) {
    return MigracaoAlunoLinha(
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      objetivo: objetivo ?? this.objetivo,
      observacao: observacao ?? this.observacao,
      duplicado: duplicado ?? this.duplicado,
      status: status ?? this.status,
      selecionado: selecionado ?? this.selecionado,
      raw: raw,
    );
  }

  /// O preview do servidor não devolve status/seleção: reaplica por posição.
  static List<MigracaoAlunoLinha> mesclarPreview(
    List<MigracaoAlunoLinha> originais,
    List<MigracaoAlunoLinha> preview,
  ) {
    if (preview.length != originais.length) return preview;
    return [
      for (var i = 0; i < preview.length; i++)
        preview[i].copyWith(
          status: originais[i].status,
          selecionado: originais[i].selecionado,
        ),
    ];
  }

  static List<MigracaoAlunoLinha>? parseLista(dynamic data) {
    if (data is! List) return null;
    return data
        .whereType<Map>()
        .map((item) => MigracaoAlunoLinha.fromJson(Map<String, dynamic>.from(item)))
        .where((row) => row.nome.isNotEmpty)
        .toList();
  }

  static List<MigracaoAlunoLinha> fromPreviewResponse(dynamic data) {
    if (data is! Map || data['alunos'] is! List) return const [];
    return parseLista(data['alunos']) ?? const [];
  }
}

/// Resultado de `/migracao/texto`: alunos + linhas descartadas.
class MigracaoTextoResultado {
  const MigracaoTextoResultado({
    required this.alunos,
    this.ignorados = 0,
    this.amostrasIgnoradas = const [],
  });

  final List<MigracaoAlunoLinha> alunos;
  final int ignorados;
  final List<String> amostrasIgnoradas;

  static MigracaoTextoResultado? parse(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      try {
        return parse(jsonDecode(data));
      } catch (_) {
        return null;
      }
    }
    if (data is List) {
      return MigracaoTextoResultado(alunos: MigracaoAlunoLinha.parseLista(data) ?? []);
    }
    if (data is Map && data['alunos'] is List) {
      final ign = data['ignorados'];
      return MigracaoTextoResultado(
        alunos: MigracaoAlunoLinha.parseLista(data['alunos']) ?? [],
        ignorados: ign is Map ? (ign['total'] as num?)?.toInt() ?? 0 : 0,
        amostrasIgnoradas: ign is Map && ign['amostras'] is List
            ? [for (final s in ign['amostras'] as List) s.toString()]
            : const [],
      );
    }
    return null;
  }
}
