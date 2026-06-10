import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class SubmissaoCaptura {
  final int id;
  final String nome;
  final String? telefone;
  final String? email;
  final String? objetivo;
  final int? pacoteInteresseId;
  final bool convertido;
  final String criadoEm;

  SubmissaoCaptura({
    required this.id,
    required this.nome,
    required this.convertido,
    required this.criadoEm,
    this.telefone,
    this.email,
    this.objetivo,
    this.pacoteInteresseId,
  });

  factory SubmissaoCaptura.fromJson(Map<String, dynamic> j) => SubmissaoCaptura(
    id: (j['id'] as num).toInt(),
    nome: j['nome'] as String? ?? '',
    telefone: j['telefone'] as String?,
    email: j['email'] as String?,
    objetivo: j['objetivo'] as String?,
    pacoteInteresseId: (j['pacoteInteresseId'] as num?)?.toInt(),
    convertido: j['convertido'] as bool? ?? false,
    criadoEm: j['criadoEm'] as String? ?? '',
  );
}

class CapturaRepository {
  final Dio _dio;
  CapturaRepository(ApiClient c) : _dio = c.dio;

  Future<List<SubmissaoCaptura>> meus() async {
    final r = await _dio.get('/api/captura');
    return (r.data as List<dynamic>)
        .map((e) => SubmissaoCaptura.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarConvertido(int id) async {
    await _dio.post('/api/captura/$id/converter');
  }
}
