import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../models/checkin_execucao_models.dart';
import '../models/checkin_personal_home.dart';
import '../models/treino_previa.dart';
import '../utils/checkin_json.dart';
import '../utils/checkin_serie_input.dart';

export '../models/checkin_execucao_models.dart';
export 'checkin_rotas_api.dart';
import 'checkin_rotas_api.dart';

Map<String, dynamic> _requireJsonMap(dynamic data, String endpoint) =>
    checkinRequireEntityJson(data, endpoint);

class CheckinRepository {
  final Dio _dio;

  /// Aluno no app ou personal no presencial; os caminhos saem dele.
  final CanalDoCheckin canal;

  CheckinRepository(ApiClient client, {this.canal = const CanalDoAluno()}) : _dio = client.dio;

  CheckinRepository._(this._dio, this.canal);

  /// O mesmo repositório falando por outro canal.
  CheckinRepository comCanal(CanalDoCheckin outro) =>
      outro == canal ? this : CheckinRepository._(_dio, outro);

  Future<TreinoPrevia> previa(int treinoId) async {
    final r = await _dio.get('/api/checkin/treinos/$treinoId/previa');
    return TreinoPrevia.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/treinos/{id}/previa'),
    );
  }

  Future<ExecucaoTreino> iniciar(int treinoId) async {
    final r = await _dio.post(canal.iniciar(), data: canal.corpoDoTreino(treinoId));
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
      canal.exercicio(execucaoId, treinoExercicioId),
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
  }) async {
    final r = await _dio.post(
      canal.serie(execucaoId, treinoExercicioId),
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

  /// [series]: o que a tela mostra em cada série que falta; o backend grava isso.
  Future<ExecucaoExercicio> confirmarRestante(
    int execucaoId,
    int treinoExercicioId, {
    List<CheckinSerieRestante> series = const [],
  }) async {
    final r = await _dio.post(
      canal.confirmarRestante(execucaoId, treinoExercicioId),
      data: {
        'series': [
          for (final s in series)
            {
              'numero': s.numero,
              if (s.cargaKg != null) 'cargaKg': s.cargaKg,
              if (s.reps != null) 'repeticoes': '${s.reps}',
            },
        ],
      },
    );
    return ExecucaoExercicio.fromJson(
      _requireJsonMap(
        r.data,
        'POST /api/checkin/{id}/exercicio/{treinoExercicioId}/confirmar-restante',
      ),
    );
  }

  Future<ExecucaoTreino> confirmarPlano(int treinoId) async {
    final r = await _dio.post(canal.confirmarPlano(), data: canal.corpoDoTreino(treinoId));
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'POST /api/checkin/confirmar-plano'),
    );
  }

  Future<ExecucaoTreino> descartar(int execucaoId) async {
    final r = await _dio.put(canal.descartar(execucaoId));
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'PUT /api/checkin/{id}/descartar'),
    );
  }

  /// [concluidoEm]: o treino acabou sem internet (manda a hora do aparelho).
  Future<ExecucaoTreino> concluir(int execucaoId, {DateTime? concluidoEm}) async {
    final r = await _dio.put(
      canal.concluir(execucaoId),
      data: concluidoEm == null
          ? null
          : {'concluidoEm': concluidoEm.toLocal().toIso8601String().split('.').first},
    );
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'PUT checkin concluir'),
    );
  }

  /// [doPersonal]: leitura da sessão de um aluno da carteira (linha do tempo).
  Future<ExecucaoTreino> detalhe(int execucaoId, {bool doPersonal = false}) async {
    final r = await _dio.get(_leitura(doPersonal).detalhe(execucaoId));
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/{id}'),
    );
  }

  Future<SessaoEvolucaoDto> evolucaoSessao(
    int execucaoId, {
    bool doPersonal = false,
  }) async {
    final r = await _dio.get(_leitura(doPersonal).evolucao(execucaoId));
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

  /// Leitura de sessão: o personal lê pelo canal dele (o aluno do presencial
  /// não importa para o caminho de leitura).
  CanalDoCheckin _leitura(bool doPersonal) =>
      doPersonal && canal is CanalDoAluno ? const CanalPresencial(0) : canal;

  /// Os treinos da semana com tudo para a execução sem internet (JSON cru: o
  /// app guarda como veio).
  Future<Map<String, dynamic>> pacoteDaSemana() async {
    final r = await _dio.get('/api/checkin/pacote-da-semana');
    return _requireJsonMap(r.data, 'GET /api/checkin/pacote-da-semana');
  }

  /// Sessão feita sem internet, enviada de uma vez (idempotente por clienteId).
  Future<ExecucaoTreino> sessaoOffline(Map<String, dynamic> corpo) async {
    final r = await _dio.post('/api/checkin/sessoes-offline', data: corpo);
    return ExecucaoTreino.fromJson(_requireJsonMap(r.data, 'POST /api/checkin/sessoes-offline'));
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
