import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Aluno {
  final int id;
  final String nome;
  final String email;
  final String? objetivo;
  final String status;
  final String? fotoUrl;
  final bool inadimplente;
  final bool emRisco;
  final String? telefone;
  final String? whatsapp;
  final String? genero;
  final String? tipoConsultoria;
  final String statusFinanceiro;
  final String? senhaProvisoria;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    this.objetivo,
    required this.status,
    this.fotoUrl,
    this.inadimplente = false,
    this.emRisco = false,
    this.telefone,
    this.whatsapp,
    this.genero,
    this.tipoConsultoria,
    this.statusFinanceiro = 'ATIVO',
    this.senhaProvisoria,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String? ?? '',
        objetivo: json['objetivo'] as String?,
        status: json['status'] as String,
        fotoUrl: json['fotoUrl'] as String?,
        inadimplente: json['inadimplente'] as bool? ?? false,
        emRisco: json['emRisco'] as bool? ?? false,
        telefone: json['telefone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        genero: json['genero'] as String?,
        tipoConsultoria: json['tipoConsultoria'] as String?,
        statusFinanceiro: json['statusFinanceiro'] as String? ?? 'ATIVO',
        senhaProvisoria: json['senhaProvisoria'] as String?,
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

  Future<Aluno> criar({
    required String nome,
    required String email,
    String? objetivo,
    String? whatsapp,
    String? genero,
    String? tipoConsultoria,
  }) async {
    final response = await _dio.post('/api/alunos', data: {
      'nome': nome,
      'email': email,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
      if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
      if (genero != null && genero.isNotEmpty) 'genero': genero,
      if (tipoConsultoria != null && tipoConsultoria.isNotEmpty)
        'tipoConsultoria': tipoConsultoria,
    });
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> atualizarStatusFinanceiro(int alunoId, String status) async {
    await _dio.patch('/api/alunos/$alunoId/status-financeiro',
        data: {'status': status});
  }

  Future<Aluno> atualizarAluno(int id, Map<String, dynamic> data) async {
    final r = await _dio.put('/api/alunos/$id', data: data);
    return Aluno.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> excluirAluno(int id) async {
    await _dio.delete('/api/alunos/$id');
  }

  Future<List<Map<String, dynamic>>> aderenciaSemanal(int id) async {
    final response = await _dio.get('/api/alunos/$id/aderencia-semanal');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<String> gerarSenhaProvisoria(int id) async {
    final response = await _dio.post('/api/alunos/$id/gerar-senha-provisoria');
    return response.data['senhaProvisoria'] as String;
  }

  Future<Aluno> me() async {
    final response = await _dio.get('/api/alunos/me');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  // Telefone getter helper (não está no modelo ainda)
  String? getTelefone(Aluno aluno) => null;
}
