import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../utils/grupo_aula_display.dart';

class GrupoAula {
  final int id;
  final String titulo;
  final String? descricao;
  final DateTime inicio;
  final DateTime fim;
  final int capacidadeMax;
  final int inscritos;
  final String? localAula;
  final String status;
  final bool inscrito;

  GrupoAula({
    required this.id,
    required this.titulo,
    required this.inicio,
    required this.fim,
    required this.capacidadeMax,
    required this.inscritos,
    required this.status,
    this.descricao,
    this.localAula,
    this.inscrito = false,
  });

  factory GrupoAula.fromJson(Map<String, dynamic> j) => GrupoAula(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    inicio: DateTime.parse(j['inicio'] as String).toLocal(),
    fim: DateTime.parse(j['fim'] as String).toLocal(),
    capacidadeMax: (j['capacidadeMax'] as num?)?.toInt() ?? 20,
    inscritos: (j['inscritos'] as num?)?.toInt() ?? 0,
    localAula: j['localAula'] as String?,
    status: j['status'] as String? ?? 'ABERTA',
    inscrito: j['inscrito'] as bool? ?? false,
  );

  bool get lotada => !inscrito && inscritos >= capacidadeMax;
}

class GrupoAulaRepository {
  final Dio _dio;
  GrupoAulaRepository(ApiClient c) : _dio = c.dio;

  Future<Pagina<GrupoAula>> listarPersonalPagina({
    int page = 0,
    String q = '',
    GrupoAulaChip chip = GrupoAulaChip.todas,
  }) async {
    final query = q.trim();
    final chipKey = grupoAulaChipQuery(chip);
    final r = await _dio.get(
      '/api/grupo-aulas',
      queryParameters: {
        'page': page,
        'size': 20,
        if (query.isNotEmpty) 'q': query,
        if (chipKey != null) 'chip': chipKey,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/grupo-aulas devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => GrupoAula.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Pagina<GrupoAula>> disponiveisPagina({
    int page = 0,
    String q = '',
  }) async {
    final query = q.trim();
    final r = await _dio.get(
      '/api/grupo-aulas/disponiveis',
      queryParameters: {
        'page': page,
        'size': 20,
        if (query.isNotEmpty) 'q': query,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/grupo-aulas/disponiveis devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => GrupoAula.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<GrupoAula> criar({
    required String titulo,
    String? descricao,
    required DateTime inicio,
    required DateTime fim,
    int? capacidadeMax,
    String? localAula,
  }) async {
    final r = await _dio.post(
      '/api/grupo-aulas',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'inicio': inicio.toIso8601String(),
        'fim': fim.toIso8601String(),
        'capacidadeMax': capacidadeMax,
        'localAula': localAula,
      },
    );
    return GrupoAula.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> inscrever(int aulaId) async {
    await _dio.post('/api/grupo-aulas/$aulaId/inscrever');
  }

  Future<void> cancelarInscricao(int aulaId) async {
    await _dio.delete('/api/grupo-aulas/$aulaId/inscricao');
  }
}
