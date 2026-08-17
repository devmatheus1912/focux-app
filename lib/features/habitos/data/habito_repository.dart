import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class HabitoTemplate {
  final String tipo;
  final String titulo;
  final String? descricao;
  final String? icone;
  final int metaDiaria;
  final int metaSemanal;

  HabitoTemplate({
    required this.tipo,
    required this.titulo,
    this.descricao,
    this.icone,
    required this.metaDiaria,
    required this.metaSemanal,
  });

  factory HabitoTemplate.fromJson(Map<String, dynamic> j) => HabitoTemplate(
    tipo: j['tipo'] as String? ?? 'CUSTOM',
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    icone: j['icone'] as String?,
    metaDiaria: (j['metaDiaria'] as num?)?.toInt() ?? 1,
    metaSemanal: (j['metaSemanal'] as num?)?.toInt() ?? 7,
  );
}

class Habito {
  final int id;
  final String titulo;
  final String? descricao;
  final String? icone;
  final String tipo;
  final int metaDiaria;
  final int metaSemanal;
  final String? lembreteHora;
  final int feitosNaSemana;
  final bool feitoHoje;
  final int streakAtual;
  final bool badgeSemana;

  Habito({
    required this.id,
    required this.titulo,
    required this.metaSemanal,
    required this.feitosNaSemana,
    required this.feitoHoje,
    this.descricao,
    this.icone,
    this.tipo = 'CUSTOM',
    this.metaDiaria = 1,
    this.lembreteHora,
    this.streakAtual = 0,
    this.badgeSemana = false,
  });

  factory Habito.fromJson(Map<String, dynamic> j) => Habito(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    icone: j['icone'] as String?,
    tipo: j['tipo'] as String? ?? 'CUSTOM',
    metaDiaria: (j['metaDiaria'] as num?)?.toInt() ?? 1,
    metaSemanal: (j['metaSemanal'] as num?)?.toInt() ?? 7,
    lembreteHora: j['lembreteHora'] as String?,
    feitosNaSemana: (j['feitosNaSemana'] as num?)?.toInt() ?? 0,
    feitoHoje: j['feitoHoje'] as bool? ?? false,
    streakAtual: (j['streakAtual'] as num?)?.toInt() ?? 0,
    badgeSemana: j['badgeSemana'] as bool? ?? false,
  );
}

class ComplianceItem {
  final int alunoId;
  final String alunoNome;
  final int checksSemana;
  final int compliancePct;

  ComplianceItem({
    required this.alunoId,
    required this.alunoNome,
    required this.checksSemana,
    required this.compliancePct,
  });

  factory ComplianceItem.fromJson(Map<String, dynamic> j) => ComplianceItem(
    alunoId: (j['alunoId'] as num).toInt(),
    alunoNome: j['alunoNome'] as String? ?? '',
    checksSemana: (j['checksSemana'] as num?)?.toInt() ?? 0,
    compliancePct: (j['compliancePct'] as num?)?.toInt() ?? 0,
  );
}

/// BFF `GET /api/habitos/home` — lista + compliance em um round-trip.
class HabitosHomeBundle {
  final List<Habito> habitos;
  final List<ComplianceItem> compliance;

  const HabitosHomeBundle({
    required this.habitos,
    required this.compliance,
  });

  factory HabitosHomeBundle.fromJson(Map<String, dynamic> j) {
    return HabitosHomeBundle(
      habitos:
          ((j['habitos'] as List?) ?? const [])
              .map((e) => Habito.fromJson(e as Map<String, dynamic>))
              .toList(),
      compliance:
          ((j['compliance'] as List?) ?? const [])
              .map((e) => ComplianceItem.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class HabitoRepository {
  final Dio _dio;
  HabitoRepository(ApiClient c) : _dio = c.dio;

  Future<List<HabitoTemplate>> templates() async {
    final r = await _dio.get('/api/habitos/templates');
    return (r.data as List<dynamic>)
        .map((e) => HabitoTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Habito>> listar() async {
    final r = await _dio.get('/api/habitos');
    return (r.data as List<dynamic>)
        .map((e) => Habito.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// BFF tipado — first paint da tela Hábitos (lista + compliance).
  Future<HabitosHomeBundle> getHome() async {
    final r = await _dio.get('/api/habitos/home');
    return HabitosHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Habito> criar({
    required String titulo,
    String? descricao,
    String? icone,
    String? tipo,
    int? metaDiaria,
    int? metaSemanal,
    String? lembreteHora,
    int? alunoId,
  }) async {
    final r = await _dio.post(
      '/api/habitos',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'icone': icone,
        'tipo': tipo,
        'metaDiaria': metaDiaria,
        'metaSemanal': metaSemanal,
        'lembreteHora': lembreteHora,
        'alunoId': alunoId,
      },
    );
    return Habito.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> desativar(int id) async {
    await _dio.delete('/api/habitos/$id');
  }

  Future<List<ComplianceItem>> compliance() async {
    final r = await _dio.get('/api/habitos/compliance');
    return (r.data as List<dynamic>)
        .map((e) => ComplianceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Habito>> meusHabitos() async {
    final r = await _dio.get('/api/habitos/me');
    return (r.data as List<dynamic>)
        .map((e) => Habito.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({bool feito, int streak})> toggleHoje(int habitoId) async {
    final r = await _dio.post('/api/habitos/me/$habitoId/check');
    final data = r.data as Map<String, dynamic>;
    return (
      feito: data['feito'] as bool? ?? false,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
    );
  }
}
