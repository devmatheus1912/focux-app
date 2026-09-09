import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

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

class AgendaHomeBundle {
  final List<Agendamento> proximos;
  final List<Agendamento> semana;

  const AgendaHomeBundle({required this.proximos, required this.semana});

  factory AgendaHomeBundle.fromJson(Map<String, dynamic> j) => AgendaHomeBundle(
    proximos: _parseAgendamentos(j['proximos']),
    semana: _parseAgendamentos(j['semana']),
  );

  /// First paint do hub: próximos + itens da semana corrente ainda não listados.
  List<Agendamento> get firstPaintItems {
    if (semana.isEmpty) return proximos;
    final seen = {for (final ag in proximos) ag.id};
    final extra = semana.where((ag) => !seen.contains(ag.id)).toList();
    if (extra.isEmpty) return proximos;
    return [...proximos, ...extra]
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
  }
}

class AgendaRepository {
  final Dio _dio;
  AgendaRepository(ApiClient c) : _dio = c.dio;

  /// BFF tipado — first paint da Agenda (próximos + semana corrente).
  Future<AgendaHomeBundle> getHome() async {
    final r = await _dio.get('/api/agenda/home');
    return AgendaHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

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
    return Agendamento.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/api/agenda/$id');
  }

  Future<List<Agendamento>> listarSemana(String data) async {
    final r = await _dio.get(
      '/api/agenda/semana',
      queryParameters: {'data': data},
    );
    return _parseAgendamentos(r.data);
  }

  Future<Agendamento> registrarStatusAtendimento(
    int id,
    String status,
    String? obs,
  ) async {
    final r = await _dio.patch(
      '/api/agenda/$id/status-atendimento',
      data: {
        'statusAtendimento': status,
        if (obs != null && obs.isNotEmpty) 'observacoesPosAtendimento': obs,
      },
    );
    return Agendamento.fromJson(r.data);
  }

  Future<Pagina<Agendamento>> meusAgendamentosPagina({
    int page = 0,
    String q = '',
    String? status,
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
