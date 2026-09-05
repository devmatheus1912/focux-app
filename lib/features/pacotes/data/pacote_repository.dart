import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Pacote {
  final int id;
  final String titulo;
  final String? descricao;
  final double valor;
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
    valor: (j['valor'] as num?)?.toDouble() ?? 0,
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

  const PacotesHomeBundle({required this.pacotes, this.perfil});

  factory PacotesHomeBundle.fromJson(Map<String, dynamic> j) {
    final perfilJson = j['perfil'];
    return PacotesHomeBundle(
      pacotes:
          ((j['pacotes'] as List?) ?? const [])
              .map((e) => Pacote.fromJson(e as Map<String, dynamic>))
              .toList(),
      perfil:
          perfilJson is Map<String, dynamic>
              ? PacotesHomePerfil.fromJson(perfilJson)
              : null,
    );
  }
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

  /// BFF tipado — first paint da tela Planos (lista + slug da vitrine).
  Future<PacotesHomeBundle> getHome() async {
    final r = await _dio.get('/api/pacotes/home');
    return PacotesHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Pacote> criar({
    required String titulo,
    String? descricao,
    required double valor,
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
        'valor': valor,
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
