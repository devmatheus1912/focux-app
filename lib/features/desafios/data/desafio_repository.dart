import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

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
  });

  factory Desafio.fromJson(Map<String, dynamic> j) => Desafio(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    tipo: j['tipo'] as String? ?? 'HABITOS',
    metaPontos: (j['metaPontos'] as num?)?.toInt() ?? 100,
    inicio: _date(j['inicio']),
    fim: _date(j['fim']),
    grupoAulaId: (j['grupoAulaId'] as num?)?.toInt(),
    ativo: j['ativo'] as bool? ?? true,
    ranking: _ranking(j['ranking']),
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
        (e) => DesafioLeaderboardEntry.fromJson(
          Map<String, dynamic>.from(e),
        ),
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

  Future<List<Desafio>> listar() async {
    final r = await _dio.get('/api/desafios');
    return (r.data as List)
        .map((e) => Desafio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Desafio>> meus() async {
    final r = await _dio.get('/api/desafios/me');
    return (r.data as List)
        .map((e) => Desafio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Desafio> criar({
    required String titulo,
    String? descricao,
    String tipo = 'HABITOS',
    int metaPontos = 100,
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
          (e) => DesafioLeaderboardEntry.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}
