class GrupoComunidade {
  final int id;
  final String nome;
  final String descricao;
  final bool publicoParaAlunos;

  GrupoComunidade({required this.id, required this.nome, required this.descricao, required this.publicoParaAlunos});

  factory GrupoComunidade.fromJson(Map<String, dynamic> json) => GrupoComunidade(
        id: json['id'],
        nome: json['nome'],
        descricao: json['descricao'] ?? '',
        publicoParaAlunos: json['publicoParaAlunos'],
      );
}

class PostGrupo {
  final int id;
  final String conteudo;
  final String tipoAutor;
  final DateTime criadoEm;

  PostGrupo({required this.id, required this.conteudo, required this.tipoAutor, required this.criadoEm});

  factory PostGrupo.fromJson(Map<String, dynamic> json) => PostGrupo(
        id: json['id'],
        conteudo: json['conteudo'],
        tipoAutor: json['tipoAutor'],
        criadoEm: DateTime.parse(json['criadoEm']),
      );
}
