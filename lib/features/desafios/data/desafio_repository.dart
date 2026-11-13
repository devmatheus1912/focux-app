import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

class Desafio {
  final int id;
  final String titulo;
  final String? descricao;
  final String tipo;
  final int metaPontos;
  final DateTime? inicio;
  final DateTime? fim;
  final int? grupoAulaId;
  final bool ativo;
  final List<DesafioLeaderboardEntry>? ranking;

  /// Só no detalhe: ninguém contou ainda, então dá para excluir.
  final bool podeExcluir;

  /// Líder e a contagem dele (lista); nulos sem contagem.
  final String? liderNome;
  final int? liderContagem;

  /// Só no /me: a contagem e a posição do aluno (posição nula sem contagem).
  final int? minhaContagem;
  final int? minhaPosicao;

  const Desafio({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.metaPontos,
    this.descricao,
    this.inicio,
    this.fim,
    this.grupoAulaId,
    this.ativo = true,
    this.ranking,
    this.podeExcluir = false,
    this.liderNome,
    this.liderContagem,
    this.minhaContagem,
    this.minhaPosicao,
  });

  factory Desafio.fromJson(Map<String, dynamic> j) => Desafio(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    tipo: j['tipo'] as String? ?? 'HABITOS',
    metaPontos: (j['metaPontos'] as num?)?.toInt() ?? 12,
    inicio: _date(j['inicio']),
    fim: _date(j['fim']),
    grupoAulaId: (j['grupoAulaId'] as num?)?.toInt(),
    ativo: j['ativo'] as bool? ?? true,
    ranking: _ranking(j['ranking']),
    podeExcluir: j['podeExcluir'] as bool? ?? false,
    liderNome: j['liderNome'] as String?,
    liderContagem: (j['liderContagem'] as num?)?.toInt(),
    minhaContagem: (j['minhaContagem'] as num?)?.toInt(),
    minhaPosicao: (j['minhaPosicao'] as num?)?.toInt(),
  );
}

class DesafioLeaderboardEntry {
  final int alunoId;
  final String alunoNome;
  final int pontos;

  const DesafioLeaderboardEntry({
    required this.alunoId,
    required this.alunoNome,
    required this.pontos,
  });

  factory DesafioLeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      DesafioLeaderboardEntry(
        alunoId: (j['alunoId'] as num?)?.toInt() ?? 0,
        alunoNome: j['alunoNome'] as String? ?? '',
        pontos: (j['pontos'] as num?)?.toInt() ?? 0,
      );
}

DateTime? _date(dynamic raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<DesafioLeaderboardEntry>? _ranking(dynamic raw) {
  if (raw is! List) return null;
  return raw
      .whereType<Map>()
      .map(
        (e) => DesafioLeaderboardEntry.fromJson(Map<String, dynamic>.from(e)),
      )
      .toList();
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class DesafioRepository {
  final Dio _dio;
  DesafioRepository(ApiClient c) : _dio = c.dio;

  Future<Pagina<Desafio>> listarPagina({
    int page = 0,
    String q = '',
    String? tipo,
  }) async {
    final query = q.trim();
    final tipoKey = tipo?.trim() ?? '';
    final r = await _dio.get(
      '/api/desafios',
      queryParameters: {
        'page': page,
        'size': 20,
        if (query.isNotEmpty) 'q': query,
        if (tipoKey.isNotEmpty) 'tipo': tipoKey,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/desafios devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => Desafio.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Pagina<Desafio>> meusPagina({
    int page = 0,
    String q = '',
    String? tipo,
  }) async {
    final query = q.trim();
    final tipoKey = tipo?.trim() ?? '';
    final r = await _dio.get(
      '/api/desafios/me',
      queryParameters: {
        'page': page,
        'size': 20,
        if (query.isNotEmpty) 'q': query,
        if (tipoKey.isNotEmpty) 'tipo': tipoKey,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/desafios/me devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => Desafio.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Desafio> criar({
    required String titulo,
    String? descricao,
    String tipo = 'TREINOS',
    int metaPontos = 12,
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final r = await _dio.post(
      '/api/desafios',
      data: {
        'titulo': titulo,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        'tipo': tipo,
        'metaPontos': metaPontos,
        if (inicio != null) 'inicio': _isoDate(inicio),
        if (fim != null) 'fim': _isoDate(fim),
      },
    );
    return Desafio.fromJson(r.data as Map<String, dynamic>);
  }

  /// Nome, descrição, meta e data final. O tipo não muda.
  Future<void> editar(
    int id, {
    required String titulo,
    String? descricao,
    required int metaPontos,
    DateTime? fim,
  }) async {
    await _dio.put(
      '/api/desafios/$id',
      data: {
        'titulo': titulo,
        'descricao': descricao ?? '',
        'metaPontos': metaPontos,
        if (fim != null) 'fim': _isoDate(fim),
      },
    );
  }

  /// Só sem contagem; com contagem o servidor responde 409.
  Future<void> excluir(int id) async {
    await _dio.delete('/api/desafios/$id');
  }

  Future<void> encerrar(int id) async {
    await _dio.post('/api/desafios/$id/encerrar');
  }

  Future<void> participar(int id) async {
    await _dio.post('/api/desafios/$id/participar');
  }

  Future<Desafio> buscar(int id) async {
    final r = await _dio.get('/api/desafios/$id');
    return Desafio.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<DesafioLeaderboardEntry>> leaderboard(int id) async {
    final r = await _dio.get('/api/desafios/$id/leaderboard');
    return (r.data as List)
        .whereType<Map>()
        .map(
          (e) => DesafioLeaderboardEntry.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }
}
