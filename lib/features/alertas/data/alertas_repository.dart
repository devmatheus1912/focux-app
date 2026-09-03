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
  final String? ultimoTreino;
  final int checkIns30Dias;
  final String statusFinanceiro;
  final String sugestaoIa;
  final String sugestaoFonte;
  final bool podeGerarIa;

  AlertaDetalhe({
    required this.alunoId,
    required this.alunoNome,
    this.ultimoTreino,
    required this.checkIns30Dias,
    required this.statusFinanceiro,
    required this.sugestaoIa,
    this.sugestaoFonte = 'LOCAL',
    this.podeGerarIa = false,
  });

  AlertaDetalhe copyWith({String? sugestaoIa, String? sugestaoFonte}) =>
      AlertaDetalhe(
        alunoId: alunoId,
        alunoNome: alunoNome,
        ultimoTreino: ultimoTreino,
        checkIns30Dias: checkIns30Dias,
        statusFinanceiro: statusFinanceiro,
        sugestaoIa: sugestaoIa ?? this.sugestaoIa,
        sugestaoFonte: sugestaoFonte ?? this.sugestaoFonte,
        podeGerarIa: podeGerarIa,
      );

  factory AlertaDetalhe.fromJson(Map<String, dynamic> j) => AlertaDetalhe(
    alunoId: (j['alunoId'] as num).toInt(),
    alunoNome: j['alunoNome'] as String? ?? '',
    ultimoTreino: j['ultimoTreino'] as String?,
    checkIns30Dias: (j['checkIns30Dias'] as num?)?.toInt() ?? 0,
    statusFinanceiro: j['statusFinanceiro'] as String? ?? '',
    sugestaoIa: j['sugestaoIa'] as String? ?? '',
    sugestaoFonte: (j['sugestaoFonte'] as String? ?? 'LOCAL').toUpperCase(),
    podeGerarIa: j['podeGerarIa'] as bool? ?? false,
  );
}

class AlertasHomeBundle {
  final List<AlertaRisco> riscos;
  final AlertasConfiguracao configuracao;
  final int page;
  final int totalRiscos;
  final bool hasNext;

  const AlertasHomeBundle({
    required this.riscos,
    required this.configuracao,
    this.page = 0,
    this.totalRiscos = 0,
    this.hasNext = false,
  });

  factory AlertasHomeBundle.fromJson(Map<String, dynamic> j) {
    final configJson = j['configuracao'];
    final riscos =
        ((j['riscos'] as List?) ?? const [])
            .map((e) => AlertaRisco.fromJson(e as Map<String, dynamic>))
            .toList();
    return AlertasHomeBundle(
      riscos: riscos,
      configuracao:
          configJson is Map<String, dynamic>
              ? AlertasConfiguracao.fromJson(configJson)
              : AlertasConfiguracao(diasSemTreino: 7, aderenciaMinima: 60),
      page: (j['page'] as num?)?.toInt() ?? 0,
      totalRiscos: (j['totalRiscos'] as num?)?.toInt() ?? riscos.length,
      hasNext: j['hasNext'] == true,
    );
  }
}

class AlertasRepository {
  final Dio _dio;
  AlertasRepository(ApiClient c) : _dio = c.dio;

  static const pageSize = 20;

  /// BFF tipado — first paint da tela Alertas (riscos + configuração).
  Future<AlertasHomeBundle> getHome({int page = 0}) async {
    final r = await _dio.get(
      '/api/alertas/home',
      queryParameters: {'page': page, 'size': pageSize},
    );
    return AlertasHomeBundle.fromJson(r.data as Map<String, dynamic>);
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

  Future<AlertaDetalhe> aplicarSugestaoIa(AlertaDetalhe atual, int alunoId) async {
    final r = await _dio.post('/api/alertas/aluno/$alunoId/sugestao-ia');
    final j = r.data as Map<String, dynamic>;
    return atual.copyWith(
      sugestaoIa: j['sugestaoIa'] as String? ?? atual.sugestaoIa,
      sugestaoFonte: (j['sugestaoFonte'] as String? ?? 'LOCAL').toUpperCase(),
    );
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
