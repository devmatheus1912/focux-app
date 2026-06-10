import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class RankingItem {
  final int personalId;
  final String nome;
  final String? logoUrl;
  final int totalAlunosAtivos;
  final int posicao;
  final int? descontoPercentual;

  RankingItem({
    required this.personalId,
    required this.nome,
    this.logoUrl,
    required this.totalAlunosAtivos,
    required this.posicao,
    this.descontoPercentual,
  });

  factory RankingItem.fromJson(Map<String, dynamic> j) => RankingItem(
        personalId: j['personalId'] as int,
        nome: j['nome'] as String,
        logoUrl: j['logoUrl'] as String?,
        totalAlunosAtivos: j['totalAlunosAtivos'] as int,
        posicao: j['posicao'] as int,
        descontoPercentual: j['descontoPercentual'] as int?,
      );
}

class RankingRepository {
  final Dio _dio;
  RankingRepository(ApiClient client) : _dio = client.dio;

  Future<List<RankingItem>> listarTop() async {
    final r = await _dio.get('/api/ranking');
    return (r.data as List)
        .map((e) => RankingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
