import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class CoachMensagem {
  final int id;
  final String tipo;
  final String mensagem;
  final String criadoEm;
  final bool lido;

  CoachMensagem({
    required this.id,
    required this.tipo,
    required this.mensagem,
    required this.criadoEm,
    required this.lido,
  });

  factory CoachMensagem.fromJson(Map<String, dynamic> j) => CoachMensagem(
    id: (j['id'] as num).toInt(),
    tipo: j['tipo'] as String? ?? '',
    mensagem: j['mensagem'] as String? ?? '',
    criadoEm: j['criadoEm'] as String? ?? '',
    lido: j['lido'] as bool? ?? false,
  );
}

class CoachHomeItem {
  const CoachHomeItem({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.tipo,
    required this.mensagem,
    required this.rota,
    required this.lido,
    required this.criadoEm,
  });

  final int id;
  final int alunoId;
  final String alunoNome;
  final String tipo;
  final String mensagem;
  final String rota;
  final bool lido;
  final String criadoEm;

  factory CoachHomeItem.fromJson(Map<String, dynamic> j) => CoachHomeItem(
    id: (j['id'] as num).toInt(),
    alunoId: (j['alunoId'] as num?)?.toInt() ?? 0,
    alunoNome: j['alunoNome'] as String? ?? 'Aluno',
    tipo: j['tipo'] as String? ?? '',
    mensagem: j['mensagem'] as String? ?? '',
    rota: j['rota'] as String? ?? '',
    lido: j['lido'] as bool? ?? false,
    criadoEm: j['criadoEm'] as String? ?? '',
  );
}

class CoachHome {
  const CoachHome({
    required this.pending,
    required this.fila,
    this.focus,
    this.itens = const [],
    this.page = 0,
    this.totalItens = 0,
    this.hasNext = false,
    this.fetchedAt,
  });

  final int pending;
  final CoachHomeItem? focus;
  final List<CoachHomeItem> fila;
  final List<CoachHomeItem> itens;
  final int page;
  final int totalItens;
  final bool hasNext;
  final DateTime? fetchedAt;

  bool get isEmpty => pending == 0 && fila.isEmpty && focus == null;

  factory CoachHome.fromJson(Map<String, dynamic> j) {
    List<CoachHomeItem> parse(String key) {
      final raw = j[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => CoachHomeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    final fila = parse('fila');
    final itens = parse('itens');
    final focusJson = j['focus'];
    return CoachHome(
      pending: (j['pending'] as num?)?.toInt() ?? 0,
      focus:
          focusJson is Map
              ? CoachHomeItem.fromJson(Map<String, dynamic>.from(focusJson))
              : null,
      fila: fila,
      itens: itens.isEmpty ? fila : itens,
      page: (j['page'] as num?)?.toInt() ?? 0,
      totalItens:
          (j['totalItens'] as num?)?.toInt() ??
          (itens.isEmpty ? fila.length : itens.length),
      hasNext: j['hasNext'] == true,
      fetchedAt: DateTime.tryParse(j['fetchedAt']?.toString() ?? ''),
    );
  }
}

class CoachProativoRepository {
  final Dio _dio;
  CoachProativoRepository(ApiClient c) : _dio = c.dio;

  Future<List<CoachMensagem>> mensagens() async {
    final r = await _dio.get('/api/coach-proativo/mensagens');
    return (r.data as List)
        .map((e) => CoachMensagem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static const homePageSize = 20;

  Future<CoachHome> getHome({int page = 0, String? q}) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      '/api/coach-proativo/home',
      queryParameters: {
        'page': page,
        'size': homePageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return CoachHome.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<void> marcarLido(int id) async {
    await _dio.post('/api/coach-proativo/mensagens/$id/lido');
  }
}
