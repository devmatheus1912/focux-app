import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Plano {
  final int id;
  final String nome;
  final double precoMensal;
  final int? limiteAlunos;
  final bool temWhiteLabel;
  final bool temFinanceiro;
  final bool temAgenda;
  final bool temRelatorios;

  Plano({
    required this.id,
    required this.nome,
    required this.precoMensal,
    this.limiteAlunos,
    required this.temWhiteLabel,
    required this.temFinanceiro,
    required this.temAgenda,
    required this.temRelatorios,
  });

  factory Plano.fromJson(Map<String, dynamic> json) => Plano(
        id: json['id'] as int,
        nome: json['nome'] as String,
        precoMensal: (json['precoMensal'] as num).toDouble(),
        limiteAlunos: json['limiteAlunos'] as int?,
        temWhiteLabel: json['temWhiteLabel'] as bool,
        temFinanceiro: json['temFinanceiro'] as bool,
        temAgenda: json['temAgenda'] as bool,
        temRelatorios: json['temRelatorios'] as bool,
      );
}

class AssinaturaRepository {
  final Dio _dio;

  AssinaturaRepository(ApiClient client) : _dio = client.dio;

  Future<List<Plano>> listarPlanos() async {
    final response = await _dio.get('/api/planos');
    final list = response.data as List<dynamic>;
    return list.map((e) => Plano.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> criarPreferencia(int planoId) async {
    final response = await _dio.post('/api/pagamentos/preferencia/$planoId');
    return response.data['checkoutUrl'] as String;
  }
}
