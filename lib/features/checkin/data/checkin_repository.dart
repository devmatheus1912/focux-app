import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../models/checkin_execucao_models.dart';
import '../models/checkin_personal_home.dart';
import '../models/treino_previa.dart';
import '../utils/checkin_json.dart';

export '../models/checkin_execucao_models.dart';

Map<String, dynamic> _requireJsonMap(dynamic data, String endpoint) =>
    checkinRequireEntityJson(data, endpoint);

class CheckinRepository {
  final Dio _dio;

  CheckinRepository(ApiClient client) : _dio = client.dio;

  Future<TreinoPrevia> previa(int treinoId) async {
    final r = await _dio.get('/api/checkin/treinos/$treinoId/previa');
    return TreinoPrevia.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/treinos/{id}/previa'),
    );
  }

  Future<ExecucaoTreino> iniciar(int treinoId) async {
    final r = await _dio.post(
      '/api/checkin/iniciar',
      data: {'treinoId': treinoId},
    );
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'POST /api/checkin/iniciar'),
    );
  }

  Future<ExecucaoExercicio> marcarExercicio(
    int execucaoId,
    int treinoExercicioId,
    int seriesFeitas, {
    String? feedback,
    int? rpe,
    bool? dor,
  }) async {
    final r = await _dio.put(
      '/api/checkin/$execucaoId/exercicio/$treinoExercicioId',
      data: {
        'seriesFeitas': seriesFeitas,
        if (feedback != null) 'feedback': feedback,
        if (rpe != null) 'rpe': rpe,
        if (dor != null) 'dor': dor,
      },
    );
    return ExecucaoExercicio.fromJson(
      _requireJsonMap(
        r.data,
        'PUT /api/checkin/{id}/exercicio/{treinoExercicioId}',
      ),
    );
  }

  Future<ExecucaoExercicio> registrarSerie(
    int execucaoId,
    int treinoExercicioId, {
    required int numero,
    double? cargaKg,
    String? repeticoes,
    String? feedback,
    int? rpe,
    bool? dor,
    int? presencialAlunoId,
  }) async {
    final path =
        presencialAlunoId != null
            ? '/api/checkin/personal/$execucaoId/exercicio/$treinoExercicioId/series'
            : '/api/checkin/$execucaoId/exercicio/$treinoExercicioId/series';
    final r = await _dio.post(
      path,
      data: {
        'numero': numero,
        if (cargaKg != null) 'cargaKg': cargaKg,
        if (repeticoes != null && repeticoes.isNotEmpty)
          'repeticoes': repeticoes,
        if (feedback != null) 'feedback': feedback,
        if (rpe != null) 'rpe': rpe,
        if (dor != null) 'dor': dor,
      },
    );
    return ExecucaoExercicio.fromJson(
      _requireJsonMap(
        r.data,
        'POST checkin serie',
      ),
    );
  }

  Future<ExecucaoExercicio> confirmarRestante(
    int execucaoId,
    int treinoExercicioId,
  ) async {
    final r = await _dio.post(
      '/api/checkin/$execucaoId/exercicio/$treinoExercicioId/confirmar-restante',
    );
    return ExecucaoExercicio.fromJson(
      _requireJsonMap(
        r.data,
        'POST /api/checkin/{id}/exercicio/{treinoExercicioId}/confirmar-restante',
      ),
    );
  }

  Future<ExecucaoTreino> confirmarPlano(int treinoId) async {
    final r = await _dio.post(
      '/api/checkin/confirmar-plano',
      data: {'treinoId': treinoId},
    );
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'POST /api/checkin/confirmar-plano'),
    );
  }

  Future<ExecucaoTreino> descartar(int execucaoId) async {
    final r = await _dio.put('/api/checkin/$execucaoId/descartar');
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'PUT /api/checkin/{id}/descartar'),
    );
  }

  Future<ExecucaoTreino> concluir(
    int execucaoId, {
    int? presencialAlunoId,
  }) async {
    final path =
        presencialAlunoId != null
            ? '/api/checkin/personal/$execucaoId/concluir'
            : '/api/checkin/$execucaoId/concluir';
    final r = await _dio.put(path);
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'PUT checkin concluir'),
    );
  }

  Future<ExecucaoTreino> detalhe(int execucaoId) async {
    final r = await _dio.get('/api/checkin/$execucaoId');
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/{id}'),
    );
  }

  Future<SessaoEvolucaoDto> evolucaoSessao(int execucaoId) async {
    final r = await _dio.get('/api/checkin/$execucaoId/evolucao-sessao');
    return SessaoEvolucaoDto.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/{id}/evolucao-sessao'),
    );
  }

  /// Só sessões concluídas; a aberta vive no hub. [treinoId] filtra por ficha.
  Future<Pagina<ExecucaoTreino>> historicoConcluidos({
    String? cursor,
    int? treinoId,
    int size = 20,
  }) async {
    final r = await _dio.get(
      '/api/checkin/historico',
      queryParameters: {
        'size': size,
        'status': 'CONCLUIDO',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (treinoId != null) 'treinoId': treinoId,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/checkin/historico devolve Pagina, não lista crua.',
      );
    }
    return parseExecucaoTreinoPagina(Map<String, dynamic>.from(data));
  }

  static const personalHomePageSize = 20;

  Future<CheckinPersonalHomeBundle> personalHome({
    int page = 0,
    String? q,
  }) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      '/api/checkin/personal/home',
      queryParameters: {
        'page': page,
        'size': personalHomePageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return CheckinPersonalHomeBundle.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/personal/home'),
    );
  }
}
