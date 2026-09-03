import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

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
    personalId: (j['personalId'] as num).toInt(),
    nome: j['nome'] as String? ?? 'Personal',
    logoUrl: j['logoUrl'] as String?,
    totalAlunosAtivos: (j['totalAlunosAtivos'] as num?)?.toInt() ?? 0,
    posicao: (j['posicao'] as num?)?.toInt() ?? 0,
    descontoPercentual: (j['descontoPercentual'] as num?)?.toInt(),
  );
}

class RankingRepository {
  final Dio _dio;
  RankingRepository(ApiClient client) : _dio = client.dio;

  static const pageSize = 20;

  Future<Pagina<RankingItem>> listar({int page = 0, String q = ''}) async {
    final query = q.trim();
    final r = await _dio.get(
      '/api/ranking',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return Pagina.fromJson(
      r.data as Map<String, dynamic>,
      (item) => RankingItem.fromJson(item as Map<String, dynamic>),
    );
  }
}
