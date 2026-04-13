import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Aluno {
  final int id;
  final String nome;
  final String email;
  final String? objetivo;
  final String status;
  final String? fotoUrl;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    this.objetivo,
    required this.status,
    this.fotoUrl,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        objetivo: json['objetivo'] as String?,
        status: json['status'] as String,
        fotoUrl: json['fotoUrl'] as String?,
      );
}

class AlunoRepository {
  final Dio _dio;

  AlunoRepository(ApiClient client) : _dio = client.dio;

  Future<List<Aluno>> listar() async {
    final response = await _dio.get('/api/alunos');
    final list = response.data as List<dynamic>;
    return list.map((e) => Aluno.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Aluno> buscar(int id) async {
    final response = await _dio.get('/api/alunos/$id');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> criar(String nome, String email, String? objetivo) async {
    final response = await _dio.post('/api/alunos', data: {
      'nome': nome,
      'email': email,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
    });
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }
}
