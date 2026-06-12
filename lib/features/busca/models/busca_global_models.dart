import 'package:flutter/material.dart';

/// Modelos da busca global — parse na borda API → UI tipada.
class BuscaItem {
  BuscaItem({
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

  factory BuscaItem.fromJson(Map<String, dynamic> json) => BuscaItem(
    id: json['id'] as int,
    titulo: json['titulo'] ?? json['nome'] ?? '',
    subtitulo: json['subtitulo'] ?? json['email'] ?? json['objetivo'],
    tipo: json['tipo'] as String,
    url: json['url'] as String,
  );
}

class BuscaGlobalResult {
  BuscaGlobalResult({
    required this.alunos,
    required this.treinos,
    required this.cobrancas,
  });

  final List<BuscaItem> alunos;
  final List<BuscaItem> treinos;
  final List<BuscaItem> cobrancas;

  factory BuscaGlobalResult.fromJson(Map<String, dynamic> json) =>
      BuscaGlobalResult(
        alunos:
            (json['alunos'] as List? ?? [])
                .map((e) => BuscaItem.fromJson(e as Map<String, dynamic>))
                .toList(),
        treinos:
            (json['treinos'] as List? ?? [])
                .map((e) => BuscaItem.fromJson(e as Map<String, dynamic>))
                .toList(),
        cobrancas:
            (json['cobrancas'] as List? ?? [])
                .map((e) => BuscaItem.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

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

  IconData get icon => switch (this) {
    BuscaTipo.todos => Icons.search,
    BuscaTipo.aluno => Icons.person,
    BuscaTipo.treino => Icons.fitness_center,
    BuscaTipo.cobranca => Icons.attach_money,
  };
}
