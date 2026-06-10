import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Pacote {
  final int id;
  final String titulo;
  final String? descricao;
  final double valor;
  final int duracaoMeses;
  final bool incluiTreino;
  final bool incluiNutri;
  final bool incluiConsultoria;
  final bool destaque;
  final bool ativo;

  Pacote({
    required this.id,
    required this.titulo,
    required this.valor,
    required this.duracaoMeses,
    required this.incluiTreino,
    required this.incluiNutri,
    required this.incluiConsultoria,
    required this.destaque,
    required this.ativo,
    this.descricao,
  });

  factory Pacote.fromJson(Map<String, dynamic> j) => Pacote(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    valor: (j['valor'] as num?)?.toDouble() ?? 0,
    duracaoMeses: (j['duracaoMeses'] as num?)?.toInt() ?? 1,
    incluiTreino: j['incluiTreino'] as bool? ?? false,
    incluiNutri: j['incluiNutri'] as bool? ?? false,
    incluiConsultoria: j['incluiConsultoria'] as bool? ?? false,
    destaque: j['destaque'] as bool? ?? false,
    ativo: j['ativo'] as bool? ?? true,
  );
}

class PacoteRepository {
  final Dio _dio;
  PacoteRepository(ApiClient c) : _dio = c.dio;

  Future<List<Pacote>> listar() async {
    final r = await _dio.get('/api/pacotes');
    return (r.data as List<dynamic>)
        .map((e) => Pacote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Pacote> criar({
    required String titulo,
    String? descricao,
    required double valor,
    int duracaoMeses = 1,
    bool incluiTreino = true,
    bool incluiNutri = false,
    bool incluiConsultoria = false,
    bool destaque = false,
  }) async {
    final r = await _dio.post(
      '/api/pacotes',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'valor': valor,
        'duracaoMeses': duracaoMeses,
        'incluiTreino': incluiTreino,
        'incluiNutri': incluiNutri,
        'incluiConsultoria': incluiConsultoria,
        'destaque': destaque,
      },
    );
    return Pacote.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> desativar(int id) async {
    await _dio.delete('/api/pacotes/$id');
  }
}
