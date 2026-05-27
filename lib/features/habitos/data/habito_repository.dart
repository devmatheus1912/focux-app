import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Habito {
  final int id;
  final String titulo;
  final String? descricao;
  final String? icone;
  final int metaSemanal;
  final int feitosNaSemana;
  final bool feitoHoje;

  Habito({
    required this.id,
    required this.titulo,
    required this.metaSemanal,
    required this.feitosNaSemana,
    required this.feitoHoje,
    this.descricao,
    this.icone,
  });

  factory Habito.fromJson(Map<String, dynamic> j) => Habito(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    icone: j['icone'] as String?,
    metaSemanal: (j['metaSemanal'] as num?)?.toInt() ?? 7,
    feitosNaSemana: (j['feitosNaSemana'] as num?)?.toInt() ?? 0,
    feitoHoje: j['feitoHoje'] as bool? ?? false,
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

class HabitoRepository {
  final Dio _dio;
  HabitoRepository(ApiClient c) : _dio = c.dio;

  Future<List<Habito>> listar() async {
    final r = await _dio.get('/api/habitos');
    return (r.data as List<dynamic>)
        .map((e) => Habito.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Habito> criar({
    required String titulo,
    String? descricao,
    String? icone,
    int? metaSemanal,
    int? alunoId,
  }) async {
    final r = await _dio.post('/api/habitos', data: {
      'titulo': titulo,
      'descricao': descricao,
      'icone': icone,
      'metaSemanal': metaSemanal,
      'alunoId': alunoId,
    });
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

  Future<bool> toggleHoje(int habitoId) async {
    final r = await _dio.post('/api/habitos/me/$habitoId/check');
    final data = r.data as Map<String, dynamic>;
    return data['feito'] as bool? ?? false;
  }
}
