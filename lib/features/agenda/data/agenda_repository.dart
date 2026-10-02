import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/offline_queued_ack.dart';
import '../../../core/api/pagina.dart';
import '../utils/agenda_schedule.dart';

class Agendamento {
  final int id;
  final int alunoId;
  final String alunoNome;
  final DateTime inicio;
  final DateTime fim;
  final String? titulo;
  final String? observacoes;
  final String status;
  final String? statusAtendimento;
  final String? observacoesPosAtendimento;

  Agendamento({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.inicio,
    required this.fim,
    this.titulo,
    this.observacoes,
    required this.status,
    this.statusAtendimento,
    this.observacoesPosAtendimento,
  });

  factory Agendamento.fromJson(Map<String, dynamic> j) => Agendamento(
    id: j['id'] as int,
    alunoId: j['alunoId'] as int,
    alunoNome: j['alunoNome'] as String,
    inicio: DateTime.parse(j['inicio'] as String).toLocal(),
    fim: DateTime.parse(j['fim'] as String).toLocal(),
    titulo: j['titulo'] as String?,
    observacoes: j['observacoes'] as String?,
    status: j['status'] as String,
    statusAtendimento: j['statusAtendimento'] as String?,
    observacoesPosAtendimento: j['observacoesPosAtendimento'] as String?,
  );
}

List<Agendamento> _parseAgendamentos(dynamic raw) =>
    ((raw as List?) ?? const [])
        .map((e) => Agendamento.fromJson(e as Map<String, dynamic>))
        .toList();

class AgendaRepository {
  final Dio _dio;
  AgendaRepository(ApiClient c) : _dio = c.dio;

  Future<Agendamento> criar(
    int alunoId,
    DateTime inicio,
    DateTime fim,
    String? titulo,
  ) async {
    final r = await _dio.post(
      '/api/agenda',
      data: {
        'alunoId': alunoId,
        'inicio': inicio.toIso8601String(),
        'fim': fim.toIso8601String(),
        if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
      },
    );
    throwIfQueuedOffline(r);
    return Agendamento.fromJson(r.data);
  }

  Future<Agendamento> atualizarHorario(
    int id,
    DateTime inicio,
    DateTime fim, {
    String? titulo,
  }) async {
    final r = await _dio.patch(
      '/api/agenda/$id',
      data: {
        'inicio': inicio.toIso8601String(),
        'fim': fim.toIso8601String(),
        if (titulo != null) 'titulo': titulo,
      },
    );
    return Agendamento.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Agendamento> atualizarStatus(int id, String status) async {
    final r = await _dio.put(
      '/api/agenda/$id/status',
      queryParameters: {'status': status},
    );
    throwIfQueuedOffline(r);
    return Agendamento.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> excluir(int id) async {
    throwIfQueuedOffline(await _dio.delete('/api/agenda/$id'));
  }

  Future<List<Agendamento>> listarSemana(String data) async {
    final r = await _dio.get(
      '/api/agenda/semana',
      queryParameters: {'data': data},
    );
    return _parseAgendamentos(r.data);
  }

  /// Grade de 6 semanas do mês. Backend antigo sem `/mes`: junta as 6 semanas.
  Future<List<Agendamento>> listarMes(int ano, int mes) async {
    try {
      final r = await _dio.get(
        '/api/agenda/mes',
        queryParameters: {'ano': ano, 'mes': mes},
      );
      return _parseAgendamentos(r.data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != 404 && code != 405) rethrow;
    }
    final first = DateTime(ano, mes);
    final semanas = await Future.wait([
      for (var i = 0; i < 6; i++)
        listarSemana(
          agendaIsoDate(DateTime(ano, mes, 2 - first.weekday + i * 7)),
        ),
    ]);
    final seen = <int>{};
    return [
      for (final semana in semanas)
        for (final ag in semana)
          if (seen.add(ag.id)) ag,
    ];
  }

  /// [escopo]: `proximas` (fim >= agora, crescente) ou `anteriores`
  /// (fim < agora, decrescente). Nulo devolve tudo.
  Future<Pagina<Agendamento>> meusAgendamentosPagina({
    int page = 0,
    String q = '',
    String? status,
    String? escopo,
  }) async {
    final query = q.trim();
    final statusKey = status?.trim() ?? '';
    final r = await _dio.get(
      '/api/agenda/aluno/meus',
      queryParameters: {
        'page': page,
        'size': 20,
        if (query.isNotEmpty) 'q': query,
        if (statusKey.isNotEmpty) 'status': statusKey,
        if (escopo != null) 'escopo': escopo,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/agenda/aluno/meus devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => Agendamento.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Agendamento> confirmarPresenca(int id) async {
    final r = await _dio.post('/api/agenda/$id/confirmar');
    throwIfQueuedOffline(r);
    return Agendamento.fromJson(r.data as Map<String, dynamic>);
  }

  Future<IcalTokenInfo> icalToken() async {
    final r = await _dio.get('/api/agenda/ical/me');
    return IcalTokenInfo.fromJson(r.data as Map<String, dynamic>);
  }

  Future<IcalTokenInfo> icalTokenAluno() async {
    final r = await _dio.get('/api/agenda/aluno/ical/me');
    return IcalTokenInfo.fromJson(r.data as Map<String, dynamic>);
  }
}

class IcalTokenInfo {
  final String token;
  final String url;

  IcalTokenInfo({required this.token, required this.url});

  factory IcalTokenInfo.fromJson(Map<String, dynamic> j) => IcalTokenInfo(
    token: j['token'] as String? ?? '',
    url: j['url'] as String? ?? '',
  );
}
