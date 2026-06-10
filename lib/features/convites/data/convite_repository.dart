import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Convite {
  final String token;
  final String link;
  final String? webLink;
  final DateTime? expiraEm;

  Convite({
    required this.token,
    required this.link,
    this.webLink,
    this.expiraEm,
  });

  String get shareLink =>
      (webLink != null && webLink!.isNotEmpty) ? webLink! : link;

  factory Convite.fromJson(Map<String, dynamic> json) => Convite(
    token: json['token'] as String,
    link: json['link'] as String,
    webLink: json['webLink'] as String?,
    expiraEm: _parseDate(json['expiraEm']),
  );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class ConviteValidacao {
  final bool valido;
  final String? personalNome;
  final String? mensagem;

  ConviteValidacao({required this.valido, this.personalNome, this.mensagem});

  factory ConviteValidacao.fromJson(Map<String, dynamic> json) =>
      ConviteValidacao(
        valido: json['valido'] as bool? ?? false,
        personalNome: json['personalNome'] as String?,
        mensagem: json['mensagem'] as String?,
      );
}

class ConviteRepository {
  final Dio _dio;

  ConviteRepository(ApiClient client) : _dio = client.dio;

  Future<Convite> gerar() async {
    final response = await _dio.post('/api/convites/gerar');
    return Convite.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConviteValidacao> validar(String token) async {
    final response = await _dio.get('/api/convites/validar/$token');
    return ConviteValidacao.fromJson(response.data as Map<String, dynamic>);
  }
}
