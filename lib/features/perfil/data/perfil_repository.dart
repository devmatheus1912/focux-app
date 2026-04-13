import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class PerfilPersonal {
  final int id;
  final String nome;
  final String email;
  final String? cref;
  final String? especialidade;
  final String? logoUrl;
  final String? corPrimaria;
  final String plano;

  PerfilPersonal({
    required this.id,
    required this.nome,
    required this.email,
    this.cref,
    this.especialidade,
    this.logoUrl,
    this.corPrimaria,
    required this.plano,
  });

  factory PerfilPersonal.fromJson(Map<String, dynamic> json) => PerfilPersonal(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        cref: json['cref'] as String?,
        especialidade: json['especialidade'] as String?,
        logoUrl: json['logoUrl'] as String?,
        corPrimaria: json['corPrimaria'] as String?,
        plano: json['plano'] as String,
      );
}

class PerfilRepository {
  final Dio _dio;

  PerfilRepository(ApiClient client) : _dio = client.dio;

  Future<PerfilPersonal> buscar() async {
    final response = await _dio.get('/api/personal/perfil');
    return PerfilPersonal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PerfilPersonal> atualizar({
    String? nome,
    String? cref,
    String? especialidade,
    String? logoUrl,
    String? corPrimaria,
  }) async {
    final response = await _dio.put('/api/personal/perfil', data: {
      if (nome != null) 'nome': nome,
      if (cref != null) 'cref': cref,
      if (especialidade != null) 'especialidade': especialidade,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (corPrimaria != null) 'corPrimaria': corPrimaria,
    });
    return PerfilPersonal.fromJson(response.data as Map<String, dynamic>);
  }
}
