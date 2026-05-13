import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AlertaRisco {
  final int alunoId;
  final String alunoNome;
  final int score;
  final List<String> motivos;
  final int? diasSemTreino;
  final double? aderenciaPercent;

  AlertaRisco({
    required this.alunoId,
    required this.alunoNome,
    required this.score,
    required this.motivos,
    this.diasSemTreino,
    this.aderenciaPercent,
  });

  factory AlertaRisco.fromJson(Map<String, dynamic> j) => AlertaRisco(
    alunoId: (j['alunoId'] as num).toInt(),
    alunoNome: j['alunoNome'] as String,
    score: j['score'] as int,
    motivos: (j['motivos'] as List).map((e) => e as String).toList(),
    diasSemTreino:
        j['diasSemTreino'] != null ? (j['diasSemTreino'] as num).toInt() : null,
    aderenciaPercent:
        j['aderenciaPercent'] != null
            ? (j['aderenciaPercent'] as num).toDouble()
            : null,
  );
}

class AlertasConfiguracao {
  final int diasSemTreino;
  final int aderenciaMinima;

  AlertasConfiguracao({
    required this.diasSemTreino,
    required this.aderenciaMinima,
  });

  factory AlertasConfiguracao.fromJson(Map<String, dynamic> j) =>
      AlertasConfiguracao(
        diasSemTreino: j['diasSemTreino'] as int,
        aderenciaMinima: j['aderenciaMinima'] as int,
      );
}

class AlertaDetalhe {
  final int alunoId;
  final String alunoNome;
  final String alunoEmail;
  final String? ultimoTreino;
  final int checkIns30Dias;
  final String statusFinanceiro;
  final String sugestaoIa;

  AlertaDetalhe({
    required this.alunoId,
    required this.alunoNome,
    required this.alunoEmail,
    this.ultimoTreino,
    required this.checkIns30Dias,
    required this.statusFinanceiro,
    required this.sugestaoIa,
  });

  factory AlertaDetalhe.fromJson(Map<String, dynamic> j) => AlertaDetalhe(
    alunoId: (j['alunoId'] as num).toInt(),
    alunoNome: j['alunoNome'] as String,
    alunoEmail: j['alunoEmail'] as String,
    ultimoTreino: j['ultimoTreino'] as String?,
    checkIns30Dias: (j['checkIns30Dias'] as num).toInt(),
    statusFinanceiro: j['statusFinanceiro'] as String,
    sugestaoIa: j['sugestaoIa'] as String,
  );
}

class AlertasRepository {
  final Dio _dio;
  AlertasRepository(ApiClient c) : _dio = c.dio;

  Future<List<AlertaRisco>> listarRiscos() async {
    final r = await _dio.get('/api/alertas/risco');
    return (r.data as List)
        .map((e) => AlertaRisco.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AlertasConfiguracao> getConfiguracao() async {
    final r = await _dio.get('/api/alertas/configuracao');
    return AlertasConfiguracao.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AlertasConfiguracao> atualizarConfiguracao(
    int diasSemTreino,
    int aderenciaMinima,
  ) async {
    final r = await _dio.put(
      '/api/alertas/configuracao',
      data: {
        'diasSemTreino': diasSemTreino,
        'aderenciaMinima': aderenciaMinima,
      },
    );
    return AlertasConfiguracao.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AlertaDetalhe> detalheAluno(int alunoId) async {
    final r = await _dio.get('/api/alertas/aluno/$alunoId/detalhe');
    return AlertaDetalhe.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> resolver(int alunoId) async {
    await _dio.post('/api/alertas/aluno/$alunoId/resolver');
  }

  Future<void> enviarMensagemChat(int alunoId, String mensagem) async {
    await _dio.post(
      '/api/alertas/aluno/$alunoId/mensagem-chat',
      data: {'mensagem': mensagem},
    );
  }
}
