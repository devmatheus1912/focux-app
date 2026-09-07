import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

class GalleryItem {
  final int id;
  final String fotoUrl;
  final String? legenda;
  final int ordem;
  GalleryItem({
    required this.id,
    required this.fotoUrl,
    this.legenda,
    required this.ordem,
  });
  factory GalleryItem.fromJson(Map<String, dynamic> j) => GalleryItem(
    id: j['id'] as int,
    fotoUrl: j['fotoUrl'] as String,
    legenda: j['legenda'] as String?,
    ordem: j['ordem'] as int? ?? 0,
  );
}

class GaleriaRepository {
  final Dio _dio;
  GaleriaRepository(ApiClient client) : _dio = client.dio;
  Future<List<GalleryItem>> listar() async {
    final r = await _dio.get('/api/personal/gallery');
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/personal/gallery devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => GalleryItem.fromJson(Map<String, dynamic>.from(item as Map)),
    ).content;
  }

  Future<GalleryItem> adicionar({
    required String fotoUrl,
    String? legenda,
    int ordem = 0,
  }) async {
    final r = await _dio.post(
      '/api/personal/gallery',
      data: {
        'fotoUrl': fotoUrl,
        if (legenda != null) 'legenda': legenda,
        'ordem': ordem,
      },
    );
    return GalleryItem.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deletar(int id) async {
    await _dio.delete('/api/personal/gallery/$id');
  }
}
