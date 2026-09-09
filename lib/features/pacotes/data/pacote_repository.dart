import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../../../core/money/fx_money.dart';

class Pacote {
  final int id;
  final String titulo;
  final String? descricao;
  final FxMoney valor;
  final int duracaoMeses;
  final bool incluiTreino;
  final bool incluiConsultoria;
  final bool destaque;
  final bool ativo;

  Pacote({
    required this.id,
    required this.titulo,
    required this.valor,
    required this.duracaoMeses,
    required this.incluiTreino,
    required this.incluiConsultoria,
    required this.destaque,
    required this.ativo,
    this.descricao,
  });

  factory Pacote.fromJson(Map<String, dynamic> j) => Pacote(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    valor: FxMoney.parse(j['valor']),
    duracaoMeses: (j['duracaoMeses'] as num?)?.toInt() ?? 1,
    incluiTreino: j['incluiTreino'] as bool? ?? false,
    incluiConsultoria: j['incluiConsultoria'] as bool? ?? false,
    destaque: j['destaque'] as bool? ?? false,
    ativo: j['ativo'] as bool? ?? true,
  );
}

class PacotesHomePerfil {
  final String? slug;
  final String? nome;

  const PacotesHomePerfil({this.slug, this.nome});

  factory PacotesHomePerfil.fromJson(Map<String, dynamic> j) => PacotesHomePerfil(
    slug: j['slug'] as String?,
    nome: j['nome'] as String?,
  );
}

class PacotesHomeBundle {
  final List<Pacote> pacotes;
  final PacotesHomePerfil? perfil;
  final int page;
  final bool hasNext;
  final int total;

  const PacotesHomeBundle({
    required this.pacotes,
    this.perfil,
    this.page = 0,
    this.hasNext = false,
    this.total = 0,
  });

  factory PacotesHomeBundle.fromJson(Map<String, dynamic> j) {
    final perfilJson = j['perfil'];
    final raw = (j['content'] as List?) ?? const [];
    final pacotes =
        raw.map((e) => Pacote.fromJson(e as Map<String, dynamic>)).toList();
    return PacotesHomeBundle(
      pacotes: pacotes,
      perfil:
          perfilJson is Map<String, dynamic>
              ? PacotesHomePerfil.fromJson(perfilJson)
              : null,
      page: (j['page'] as num?)?.toInt() ?? 0,
      hasNext: j['hasNext'] == true,
      total: (j['total'] as num?)?.toInt() ?? pacotes.length,
    );
  }
}

class PacoteRepository {
  final Dio _dio;
  PacoteRepository(ApiClient c) : _dio = c.dio;

  static const pageSize = 20;

  Future<Pagina<Pacote>> listar({
    int page = 0,
    String q = '',
    bool? destaque,
  }) async {
    final query = q.trim();
    final r = await _dio.get(
      '/api/pacotes',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
        if (destaque != null) 'destaque': destaque,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw const FormatException('GET /api/pacotes devolve Pagina, não lista crua.');
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => Pacote.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  /// BFF tipado — first paint da tela Planos (lista + slug da vitrine).
  Future<PacotesHomeBundle> getHome({
    int page = 0,
    String q = '',
    bool? destaque,
  }) async {
    final query = q.trim();
    final r = await _dio.get(
      '/api/pacotes/home',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
        if (destaque != null) 'destaque': destaque,
      },
    );
    return PacotesHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Pacote> criar({
    required String titulo,
    String? descricao,
    required Object valor,
    int duracaoMeses = 1,
    bool incluiTreino = true,
    bool incluiConsultoria = false,
    bool destaque = false,
  }) async {
    final r = await _dio.post(
      '/api/pacotes',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'valor': FxMoney.parse(valor).wire,
        'duracaoMeses': duracaoMeses,
        'incluiTreino': incluiTreino,
        // Backend ainda aceita o campo; app não oferece dieta/nutri.
        'incluiNutri': false,
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
