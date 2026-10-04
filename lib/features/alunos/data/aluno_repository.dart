import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../../exercicios/data/enums.dart';
import 'aluno_models.dart';

export 'aluno_models.dart';

class AlunoRepository {
  final Dio _dio;

  AlunoRepository(ApiClient client) : _dio = client.dio;

  /// Primeira página no envelope do contrato. A lista de produto usa o BFF
  /// `/home`; este GET é picker e tela que ainda não migrou.
  Future<Pagina<Aluno>> listarPagina({int page = 0, int size = 20}) async {
    final response = await _dio.get(
      '/api/alunos',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/alunos agora devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => Aluno.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  /// Drena as páginas até `hasNext == false`. Picker (recorrência) ainda
  /// precisa do conjunto; size no cap do servidor (100) para menos round-trips.
  Future<List<Aluno>> listar() async {
    final all = <Aluno>[];
    var page = 0;
    const size = 100;
    while (true) {
      final chunk = await listarPagina(page: page, size: size);
      all.addAll(chunk.content);
      if (!chunk.hasNext) break;
      page++;
      if (page >= 50) break;
    }
    return all;
  }

  /// BFF tipado — first paint da lista (alunos + stats + alertas config).
  Future<AlunosHomeBundle> getHome({
    int page = 0,
    int size = 40,
    String q = '',
    String filtro = 'todos',
    String ordenacao = 'prioridade',
  }) async {
    final response = await _dio.get(
      '/api/alunos/home',
      queryParameters: {
        'page': page,
        'size': size,
        if (q.trim().isNotEmpty) 'q': q.trim(),
        'filtro': filtro,
        'ordenacao': ordenacao,
      },
    );
    return AlunosHomeBundle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> atualizarFollowUp(
    int id, {
    String? proximoContato,
    String? snoozedUntil,
    bool clearSnooze = false,
    bool clearFollowUp = false,
  }) async {
    final response = await _dio.patch(
      '/api/alunos/$id/follow-up',
      data: {
        if (proximoContato != null) 'proximoContato': proximoContato,
        if (snoozedUntil != null) 'snoozedUntil': snoozedUntil,
        if (clearSnooze) 'clearSnooze': true,
        if (clearFollowUp) 'clearFollowUp': true,
      },
    );
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> marcarContatoRealizado(int id) async {
    final response = await _dio.post('/api/alunos/$id/contato-realizado');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cobrarTreino(int id, {int? treinoId}) async {
    await _dio.post(
      '/api/alunos/$id/cobrar-treino',
      data: {if (treinoId != null) 'treinoId': treinoId},
    );
  }

  Future<void> atualizarStatusLote(List<int> ids, String status) async {
    await _dio.patch(
      '/api/alunos/lote/status',
      data: {'alunoIds': ids, 'status': status},
    );
  }

  Future<Aluno> buscar(int id) async {
    final response = await _dio.get('/api/alunos/$id');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  /// Critical path — Operação first paint.
  Future<Aluno360Operacao> buscarAluno360Operacao(int id) async {
    final response = await _dio.get('/api/alunos/$id/360/operacao');
    return Aluno360Operacao.fromJson(response.data as Map<String, dynamic>);
  }

  /// Prefetch / lazy Evolução tab.
  Future<Aluno360Evolucao> buscarAluno360Evolucao(int id) async {
    final response = await _dio.get('/api/alunos/$id/360/evolucao');
    return Aluno360Evolucao.fromJson(response.data as Map<String, dynamic>);
  }

  /// Prefetch / lazy Ferramentas tab.
  Future<Aluno360Ferramentas> buscarAluno360Ferramentas(int id) async {
    final response = await _dio.get('/api/alunos/$id/360/ferramentas');
    return Aluno360Ferramentas.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> criar({
    required String nome,
    required String email,
    String? objetivo,
    String? whatsapp,
    String? genero,
    String? tipoConsultoria,
    int? leadId,
  }) async {
    final response = await _dio.post(
      '/api/alunos',
      data: {
        'nome': nome,
        'email': email,
        if (leadId != null) 'leadId': leadId,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        if (genero != null && genero.isNotEmpty) 'genero': genero,
        if (tipoConsultoria != null && tipoConsultoria.isNotEmpty)
          'tipoConsultoria': tipoConsultoria,
      },
    );
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> atualizarAluno(int id, Map<String, dynamic> data) async {
    final r = await _dio.put('/api/alunos/$id', data: data);
    return Aluno.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> excluirAluno(int id) async {
    await _dio.delete('/api/alunos/$id');
  }

  Future<void> atualizarEquipamentos(
    int alunoId,
    Set<Equipamento> equipamentos,
  ) async {
    await _dio.patch(
      '/api/alunos/$alunoId/equipamentos',
      data: {'equipamentos': equipamentos.map((e) => e.backendName).toList()},
    );
  }

  Future<List<Map<String, dynamic>>> aderenciaSemanal(int id) async {
    final response = await _dio.get('/api/alunos/$id/aderencia-semanal');
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return AderenciaSemanalBundle.fromJson(
      Map<String, dynamic>.from(data as Map),
    ).diasMaps;
  }

  Future<AlunoAutonomiaResumo> buscarAutonomiaResumo(int alunoId) async {
    final response = await _dio.get('/api/alunos/$alunoId/autonomia/resumo');
    return AlunoAutonomiaResumo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EvolucaoInteligente> buscarEvolucaoInteligente(int alunoId) async {
    final response = await _dio.get(
      '/api/alunos/$alunoId/evolucao-inteligente',
    );
    return EvolucaoInteligente.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Timeline360Event>> buscarTimeline360(
    int alunoId, {
    int limit = 40,
  }) async {
    final page = await buscarTimeline360Page(alunoId, limit: limit);
    return page.events;
  }

  Future<Timeline360Page> buscarTimeline360Page(
    int alunoId, {
    int limit = 40,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/api/alunos/$alunoId/timeline-360/page',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return Timeline360Page.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> gerarSenhaProvisoria(int id) async {
    final response = await _dio.post('/api/alunos/$id/gerar-senha-provisoria');
    return response.data['senhaProvisoria'] as String;
  }

  Future<Aluno> me() async {
    final response = await _dio.get('/api/aluno/me');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  /// BFF tipado — first paint da aba Perfil (aluno + medidas).
  Future<AlunoPerfilHomeBundle> getPerfilHome() async {
    final response = await _dio.get('/api/aluno/perfil/home');
    return AlunoPerfilHomeBundle.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<Aluno> atualizarMe(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/aluno/me', data: data);
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  /// Foto de perfil do aluno — pasta liberada no BE (não usa /api/uploads).
  Future<String> uploadMinhaFoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final lower = filename.toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : 'jpg';
    final contentType = switch (ext) {
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      'heic' => DioMediaType('image', 'heic'),
      'heif' => DioMediaType('image', 'heif'),
      _ => DioMediaType('image', 'jpeg'),
    };
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    });
    final response = await _dio.post('/api/aluno/me/foto', data: form);
    final data = Map<String, dynamic>.from(response.data as Map);
    final url = data['url'] as String? ?? data['fotoUrl'] as String?;
    if (url != null && url.trim().isNotEmpty) return url.trim();
    final aluno = Aluno.fromJson(data);
    final foto = aluno.fotoUrl?.trim();
    if (foto != null && foto.isNotEmpty) return foto;
    throw StateError('Upload de foto sem URL');
  }

  Future<void> registrarEventoAutonomia({
    required String taskId,
    required String taskTitle,
    required String action,
    String? route,
    String? priority,
    bool? done,
    int? profileCompletion,
  }) async {
    await _dio.post(
      '/api/aluno/autonomia/eventos',
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'action': action,
        if (route != null) 'route': route,
        if (priority != null) 'priority': priority,
        if (done != null) 'done': done,
        if (profileCompletion != null) 'profileCompletion': profileCompletion,
      },
    );
  }
}
