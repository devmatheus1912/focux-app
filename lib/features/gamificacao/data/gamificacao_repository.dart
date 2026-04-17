import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Streak {
  final int streakAtual;
  final int streakMaximo;
  final String? ultimoTreino;

  Streak({
    required this.streakAtual,
    required this.streakMaximo,
    this.ultimoTreino,
  });

  factory Streak.fromJson(Map<String, dynamic> j) => Streak(
        streakAtual: j['streakAtual'] as int,
        streakMaximo: j['streakMaximo'] as int,
        ultimoTreino: j['ultimoTreino'] as String?,
      );
}

class Badge {
  final String tipo;
  final String descricao;
  final String conquistaEm;

  Badge({
    required this.tipo,
    required this.descricao,
    required this.conquistaEm,
  });

  factory Badge.fromJson(Map<String, dynamic> j) => Badge(
        tipo: j['tipo'] as String,
        descricao: j['descricao'] as String,
        conquistaEm: j['conquistaEm'] as String,
      );
}

class GamificacaoData {
  final Streak streak;
  final List<Badge> badges;
  final int totalTreinos;

  GamificacaoData({
    required this.streak,
    required this.badges,
    required this.totalTreinos,
  });

  factory GamificacaoData.fromJson(Map<String, dynamic> j) => GamificacaoData(
        streak: Streak.fromJson(j['streak'] as Map<String, dynamic>),
        badges: (j['badges'] as List<dynamic>)
            .map((e) => Badge.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalTreinos: j['totalTreinos'] as int,
      );
}

class ReferralCupom {
  final String codigo;
  final int descontoPercentual;
  final String? cashbackDescricao;
  final bool foiUsado;

  ReferralCupom({
    required this.codigo,
    required this.descontoPercentual,
    this.cashbackDescricao,
    required this.foiUsado,
  });

  factory ReferralCupom.fromJson(Map<String, dynamic> j) => ReferralCupom(
        codigo: j['codigo'] as String,
        descontoPercentual: j['descontoPercentual'] as int,
        cashbackDescricao: j['cashbackDescricao'] as String?,
        foiUsado: j['foiUsado'] as bool,
      );
}

class GamificacaoRepository {
  final Dio _dio;

  GamificacaoRepository(ApiClient client) : _dio = client.dio;

  Future<GamificacaoData> getGamificacao() async {
    final r = await _dio.get('/api/gamificacao');
    return GamificacaoData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ReferralCupom> getReferral() async {
    final r = await _dio.get('/api/gamificacao/referral');
    return ReferralCupom.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> usarCupom(String codigo) async {
    await _dio.post('/api/gamificacao/referral/usar', queryParameters: {'codigo': codigo});
  }
}
