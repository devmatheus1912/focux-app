import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/money/fx_money.dart';

class PacoteSugerido {
  final String nome;
  final double valor;
  final String descricao;

  PacoteSugerido({
    required this.nome,
    required this.valor,
    required this.descricao,
  });

  factory PacoteSugerido.fromJson(Map<String, dynamic> j) => PacoteSugerido(
    nome: j['nome'] as String? ?? '',
    valor: FxMoney.reais(j['valor']),
    descricao: j['descricao'] as String? ?? '',
  );
}

class SmartPricingRecomendacao {
  final double ticketAtual;
  final double precoSugerido;
  final int alunosAtivos;
  final int mensalidadesPagas;
  final String rationale;
  final List<PacoteSugerido> pacotesSugeridos;

  SmartPricingRecomendacao({
    required this.ticketAtual,
    required this.precoSugerido,
    required this.alunosAtivos,
    required this.mensalidadesPagas,
    required this.rationale,
    required this.pacotesSugeridos,
  });

  factory SmartPricingRecomendacao.fromJson(Map<String, dynamic> j) =>
      SmartPricingRecomendacao(
        ticketAtual: FxMoney.reais(j['ticketAtual']),
        precoSugerido: FxMoney.reais(j['precoSugerido']),
        alunosAtivos: (j['alunosAtivos'] as num?)?.toInt() ?? 0,
        mensalidadesPagas: (j['mensalidadesPagas'] as num?)?.toInt() ?? 0,
        rationale: j['rationale'] as String? ?? '',
        pacotesSugeridos:
            (j['pacotesSugeridos'] as List<dynamic>? ?? [])
                .map((e) => PacoteSugerido.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}

class SmartPricingRepository {
  final Dio _dio;
  SmartPricingRepository(ApiClient c) : _dio = c.dio;

  Future<SmartPricingRecomendacao> recomendacao() async {
    final r = await _dio.get('/api/pricing/recomendacao');
    return SmartPricingRecomendacao.fromJson(r.data as Map<String, dynamic>);
  }
}
