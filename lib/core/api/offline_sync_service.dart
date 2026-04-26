import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de uma request mutativa enfileirada para retry quando o app
/// estiver offline. Carrega contagem de tentativas e {@code nextRetryAt}
/// para implementar backoff exponencial sem ressubmeter em loop apertado.
class QueuedRequest {
  final String path;
  final String method;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final int attempts;
  final int nextRetryAtMillis;

  QueuedRequest({
    required this.path,
    required this.method,
    this.data,
    this.queryParameters,
    this.attempts = 0,
    this.nextRetryAtMillis = 0,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'method': method,
        'data': data,
        'queryParameters': queryParameters,
        'attempts': attempts,
        'nextRetryAtMillis': nextRetryAtMillis,
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        path: json['path'] as String,
        method: json['method'] as String,
        data: json['data'],
        queryParameters: (json['queryParameters'] as Map?)?.cast<String, dynamic>(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        nextRetryAtMillis: (json['nextRetryAtMillis'] as num?)?.toInt() ?? 0,
      );

  QueuedRequest withRetry() {
    final next = attempts + 1;
    final delayMs = _backoff(next);
    return QueuedRequest(
      path: path,
      method: method,
      data: data,
      queryParameters: queryParameters,
      attempts: next,
      nextRetryAtMillis: DateTime.now().millisecondsSinceEpoch + delayMs,
    );
  }

  bool get isReadyToRetry =>
      DateTime.now().millisecondsSinceEpoch >= nextRetryAtMillis;

  static int _backoff(int attempt) {
    // 5s, 15s, 45s, 2m15s, 6m45s, 20m, então cap de 1h.
    if (attempt <= 0) return 0;
    final base = 5 * 1000;
    final exp = base * pow3(attempt - 1);
    return exp > 3600 * 1000 ? 3600 * 1000 : exp;
  }

  static int pow3(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) { r *= 3; }
    return r;
  }
}

class OfflineSyncService {
  static const _queueKey = 'offline_outbox_queue';
  static const _maxAttempts = 8;

  /// Add a failed request to the queue
  static Future<void> enqueueRequest(RequestOptions options) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_queueKey);
    final List<dynamic> queueList = queueStr != null ? jsonDecode(queueStr) : [];

    final req = QueuedRequest(
      path: options.path,
      method: options.method,
      data: options.data,
      queryParameters: options.queryParameters,
    );

    queueList.add(req.toJson());
    await prefs.setString(_queueKey, jsonEncode(queueList));
  }

  /// Get the number of pending requests
  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_queueKey);
    if (queueStr == null) return 0;
    return (jsonDecode(queueStr) as List).length;
  }

  /// Try to sync all pending requests using the provided Dio instance.
  ///
  /// Aplica backoff exponencial: requests que falharam recentemente são
  /// puladas até `nextRetryAtMillis`. Após `_maxAttempts` falhas a request
  /// é descartada para não bloquear a fila eternamente.
  static Future<void> syncPendingRequests(Dio dio) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_queueKey);
    if (queueStr == null) return;

    final List<dynamic> queueList = jsonDecode(queueStr);
    if (queueList.isEmpty) return;

    final List<dynamic> remainingList = [];

    for (final item in queueList) {
      final req = QueuedRequest.fromJson(item as Map<String, dynamic>);
      if (!req.isReadyToRetry) {
        remainingList.add(req.toJson());
        continue;
      }
      try {
        await dio.request(
          req.path,
          data: req.data,
          queryParameters: req.queryParameters,
          options: Options(method: req.method),
        );
      } catch (_) {
        if (req.attempts + 1 >= _maxAttempts) {
          // Descarta após N tentativas para não enfileirar para sempre.
          continue;
        }
        remainingList.add(req.withRetry().toJson());
      }
    }

    if (remainingList.isEmpty) {
      await prefs.remove(_queueKey);
    } else {
      await prefs.setString(_queueKey, jsonEncode(remainingList));
    }
  }
}

/// Cache local simples (KV via SharedPreferences) para responses GET.
/// Suficiente para destravar a UI offline de Hoje / Alunos / Treinos
/// sem trazer Drift/Hive imediatamente — o trade-off é não suportar
/// queries; trocar por Drift no próximo PR sem mudar a interface.
class LocalCache {
  static const _prefix = 'fx_cache_v1:';
  static const Duration defaultTtl = Duration(minutes: 30);

  static String _key(String path) => '$_prefix$path';

  static Future<void> put(String path, dynamic data, {Duration? ttl}) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'ttlMs': (ttl ?? defaultTtl).inMilliseconds,
      'data': data,
    };
    await prefs.setString(_key(path), jsonEncode(entry));
  }

  static Future<dynamic> get(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(path));
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (entry['savedAt'] as num).toInt();
      final ttlMs = (entry['ttlMs'] as num).toInt();
      final age = DateTime.now().millisecondsSinceEpoch - savedAt;
      if (age > ttlMs) return null;
      return entry['data'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> invalidate(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(path));
  }
}
