import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/state/fx_value_notifier.dart';
import '../../auth/providers/auth_provider.dart';

final notificacoesRepositoryProvider = Provider<NotificacoesRepository>(
  (ref) => NotificacoesRepository(ref.read(apiClientProvider)),
);

final notificacoesProvider =
    AsyncNotifierProvider<NotificacoesInboxNotifier, NotificacoesInbox>(
      NotificacoesInboxNotifier.new,
    );

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

class NotificacoesInbox {
  const NotificacoesInbox({
    required this.items,
    required this.hasMore,
    required this.page,
    required this.total,
    this.loadingMore = false,
  });

  final List<NotificacaoApp> items;
  final bool hasMore;
  final int page;
  final int total;
  final bool loadingMore;

  NotificacoesInbox copyWith({
    List<NotificacaoApp>? items,
    bool? hasMore,
    int? page,
    int? total,
    bool? loadingMore,
  }) {
    return NotificacoesInbox(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  factory NotificacoesInbox.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List? ?? const [];
    return NotificacoesInbox(
      items:
          raw
              .map((item) => NotificacaoApp.fromJson(item as Map<String, dynamic>))
              .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
      page: (json['page'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? raw.length,
    );
  }
}

final notificacoesQueryProvider = fxValueProvider<String>('');

class NotificacoesInboxNotifier extends AsyncNotifier<NotificacoesInbox> {
  static const pageSize = 30;

  @override
  Future<NotificacoesInbox> build() {
    final q = ref.watch(notificacoesQueryProvider);
    return ref
        .read(notificacoesRepositoryProvider)
        .listar(page: 0, size: pageSize, q: q);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(notificacoesRepositoryProvider)
          .listar(
            page: current.page + 1,
            size: pageSize,
            q: ref.read(notificacoesQueryProvider),
          );
      final seen = current.items.map((item) => item.id).toSet();
      state = AsyncData(
        NotificacoesInbox(
          items: [
            ...current.items,
            ...next.items.where((item) => seen.add(item.id)),
          ],
          hasMore: next.hasMore,
          page: next.page,
          total: next.total,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

class NotificacoesRepository {
  final Dio _dio;

  NotificacoesRepository(ApiClient client) : _dio = client.dio;

  Future<NotificacoesInbox> listar({
    int page = 0,
    int size = 30,
    String q = '',
  }) async {
    final query = q.trim();
    final response = await _dio.get(
      '/api/notificacoes',
      queryParameters: {
        'page': page,
        'size': size,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return NotificacoesInbox.fromJson(response.data as Map<String, dynamic>);
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
