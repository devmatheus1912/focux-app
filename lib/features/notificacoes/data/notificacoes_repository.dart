import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

final notificacoesRepositoryProvider = Provider<NotificacoesRepository>(
  (ref) => NotificacoesRepository(ref.read(apiClientProvider)),
);

final notificacoesProvider = FutureProvider<List<NotificacaoApp>>((ref) async {
  return ref.read(notificacoesRepositoryProvider).listar();
});

final notificacoesNaoLidasProvider = FutureProvider<int>((ref) async {
  return ref.read(notificacoesRepositoryProvider).totalNaoLidas();
});

class NotificacaoApp {
  final int id;
  final String titulo;
  final String mensagem;
  final String tipo;
  final bool lida;
  final String? route;
  final String? ctaLabel;
  final Map<String, dynamic> dados;
  final DateTime? criadaEm;

  const NotificacaoApp({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.lida,
    this.route,
    this.ctaLabel,
    this.dados = const {},
    this.criadaEm,
  });

  factory NotificacaoApp.fromJson(Map<String, dynamic> json) {
    final rawDados = json['dados'];
    return NotificacaoApp(
      id: json['id'] as int,
      titulo: json['titulo'] as String? ?? '',
      mensagem: json['mensagem'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'INFO',
      lida: json['lida'] as bool? ?? false,
      route: json['route'] as String?,
      ctaLabel: json['ctaLabel'] as String?,
      dados: rawDados is Map<String, dynamic> ? rawDados : const {},
      criadaEm: DateTime.tryParse(json['criadaEm'] as String? ?? ''),
    );
  }
}

class NotificacoesRepository {
  final Dio _dio;

  NotificacoesRepository(ApiClient client) : _dio = client.dio;

  Future<List<NotificacaoApp>> listar() async {
    final response = await _dio.get('/api/notificacoes');
    return (response.data as List<dynamic>)
        .map((item) => NotificacaoApp.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> totalNaoLidas() async {
    final response = await _dio.get('/api/notificacoes/nao-lidas/total');
    final data = response.data as Map<String, dynamic>;
    return (data['total'] as num?)?.toInt() ?? 0;
  }

  Future<NotificacaoApp> marcarLida(int id) async {
    final response = await _dio.put('/api/notificacoes/$id/ler');
    return NotificacaoApp.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> marcarTodasLidas() async {
    await _dio.put('/api/notificacoes/ler-todas');
  }
}
