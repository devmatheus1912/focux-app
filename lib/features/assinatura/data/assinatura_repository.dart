import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/payment_api_client.dart';
import '../../planos/paywall/paywall_vitrine.dart';

class Plano {
  final int id;
  final String nome;
  final double precoMensal;
  final double? precoAnual;
  final double? precoAnualMensalEquiv;
  final int? limiteAlunos;
  final bool temWhiteLabel;
  final bool temFinanceiro;
  final bool temAgenda;
  final bool temRelatorios;
  final bool temLandingCompleta;
  final String? displayName;
  final String? subtitle;
  final String? badge;
  final String? roiTag;
  final int? tierOrder;

  Plano({
    required this.id,
    required this.nome,
    required this.precoMensal,
    this.precoAnual,
    this.precoAnualMensalEquiv,
    this.limiteAlunos,
    required this.temWhiteLabel,
    required this.temFinanceiro,
    required this.temAgenda,
    required this.temRelatorios,
    this.temLandingCompleta = false,
    this.displayName,
    this.subtitle,
    this.badge,
    this.roiTag,
    this.tierOrder,
  });

  double annualPriceOrComputed() =>
      precoAnual ?? (precoMensal * 12 * 0.8);

  factory Plano.fromJson(Map<String, dynamic> json) => Plano(
    id: json['id'] as int,
    nome: json['nome'] as String,
    precoMensal: (json['precoMensal'] as num).toDouble(),
    precoAnual: (json['precoAnual'] as num?)?.toDouble(),
    precoAnualMensalEquiv: (json['precoAnualMensalEquiv'] as num?)?.toDouble(),
    limiteAlunos: json['limiteAlunos'] as int?,
    temWhiteLabel: json['temWhiteLabel'] as bool,
    temFinanceiro: json['temFinanceiro'] as bool,
    temAgenda: json['temAgenda'] as bool,
    temRelatorios: json['temRelatorios'] as bool,
    temLandingCompleta: json['temLandingCompleta'] as bool? ?? false,
    displayName: json['displayName'] as String?,
    subtitle: json['subtitle'] as String?,
    badge: json['badge'] as String?,
    roiTag: json['roiTag'] as String?,
    tierOrder: (json['tierOrder'] as num?)?.toInt(),
  );
}

class AssinaturaRepository {
  final Dio _dio;
  final Dio _paymentDio;

  AssinaturaRepository(ApiClient client, PaymentApiClient payment)
    : _dio = client.dio,
      _paymentDio = payment.dio;

  Future<List<Plano>> listarPlanos() async {
    final response = await _dio.get('/api/planos');
    final list = response.data as List<dynamic>;
    return list.map((e) => Plano.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaywallVitrineSnapshot> fetchVitrine() async {
    final response = await _dio.get('/api/planos/vitrine');
    return PaywallVitrineSnapshot.fromApi(
      response.data as Map<String, dynamic>,
    );
  }

  Future<String> criarPreferencia(int planoId) async {
    final response = await _paymentDio.post(
      '/api/pagamentos/preferencia/$planoId',
    );
    return response.data['checkoutUrl'] as String;
  }
}
