import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Mensalidade {
  final int id;
  final int alunoId;
  final String alunoNome;
  final double valor;
  final String mesReferencia;
  final String status;
  final String? pagoEm;

  Mensalidade({required this.id, required this.alunoId, required this.alunoNome,
    required this.valor, required this.mesReferencia, required this.status, this.pagoEm});

  factory Mensalidade.fromJson(Map<String, dynamic> j) => Mensalidade(
    id: j['id'] as int,
    alunoId: j['alunoId'] as int,
    alunoNome: j['alunoNome'] as String,
    valor: (j['valor'] as num).toDouble(),
    mesReferencia: j['mesReferencia'] as String,
    status: j['status'] as String,
    pagoEm: j['pagoEm'] as String?,
  );
}

class FinanceiroRepository {
  final Dio _dio;
  FinanceiroRepository(ApiClient c) : _dio = c.dio;

  Future<List<Mensalidade>> listar() async {
    final r = await _dio.get('/api/financeiro/mensalidades');
    return (r.data as List).map((e) => Mensalidade.fromJson(e)).toList();
  }

  Future<Mensalidade> criar(int alunoId, double valor, String mesReferencia) async {
    final r = await _dio.post('/api/financeiro/mensalidades', data: {
      'alunoId': alunoId,
      'valor': valor,
      'mesReferencia': mesReferencia,
    });
    return Mensalidade.fromJson(r.data);
  }

  Future<Mensalidade> pagar(int id) async {
    final r = await _dio.put('/api/financeiro/mensalidades/$id/pagar');
    return Mensalidade.fromJson(r.data);
  }
}
