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
  final String? idempotencyKey;
  final int attempts;
  final int nextRetryAtMillis;

  QueuedRequest({
    required this.path,
    required this.method,
    this.data,
    this.queryParameters,
    this.idempotencyKey,
    this.attempts = 0,
    this.nextRetryAtMillis = 0,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'method': method,
    'data': data,
    'queryParameters': queryParameters,
    'idempotencyKey': idempotencyKey,
    'attempts': attempts,
    'nextRetryAtMillis': nextRetryAtMillis,
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    path: json['path'] as String,
    method: json['method'] as String,
    data: json['data'],
    queryParameters: (json['queryParameters'] as Map?)?.cast<String, dynamic>(),
    idempotencyKey: json['idempotencyKey'] as String?,
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
      idempotencyKey: idempotencyKey,
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
    for (var i = 0; i < n; i++) {
      r *= 3;
    }
    return r;
  }
}

class OfflineSyncService {
  static const _queueKey = 'offline_outbox_queue';
  static const _maxAttempts = 8;

  /// Add a failed request to the queue (sem body sensível).
  static Future<void> enqueueRequest(RequestOptions options) async {
    if (_isSensitivePath(options.path)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_queueKey);
    final List<dynamic> queueList =
        queueStr != null ? jsonDecode(queueStr) : [];

    final req = QueuedRequest(
      path: options.path,
      method: options.method,
      data: _sanitizeQueueData(options.path, options.data),
      queryParameters: options.queryParameters,
      idempotencyKey: _readIdempotencyKey(options.headers),
    );

    queueList.add(req.toJson());
    await prefs.setString(_queueKey, jsonEncode(queueList));
  }

  static bool _isSensitivePath(String path) {
    final p = path.toLowerCase();
    return p.contains('/chat') ||
        p.contains('/anamnese') ||
        p.contains('/health') ||
        p.contains('/lgpd') ||
        p.contains('/wallet') ||
        p.contains('/mensalidade') ||
        p.contains('/pagamento') ||
        p.contains('/auth');
  }

  static dynamic _sanitizeQueueData(String path, dynamic data) {
    if (data == null) return null;
    if (data is FormData) return null;
    if (_isSensitivePath(path)) return null;
    return data;
  }

  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
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
          options: Options(
            method: req.method,
            headers: {
              if (req.idempotencyKey != null)
                'Idempotency-Key': req.idempotencyKey,
            },
          ),
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

  static String? _readIdempotencyKey(Map<String, dynamic> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'idempotency-key') {
        final value = entry.value?.toString();
        return value == null || value.isEmpty ? null : value;
      }
    }
    return null;
  }
}

/// Cache local simples (KV via SharedPreferences) para responses GET.
/// Suficiente para destravar a UI offline de Hoje / Alunos / Treinos
/// sem trazer Drift/Hive imediatamente — o trade-off é não suportar
/// queries; trocar por Drift no próximo PR sem mudar a interface.
class LocalCache {
  static const _prefix = 'fx_cache_v1:';
  static const Duration defaultTtl = Duration(minutes: 30);

  static String keyFor(RequestOptions options) {
    final query = _canonicalQuery(options.queryParameters);
    if (query.isEmpty) return options.path;
    return '${options.path}?$query';
  }

  static String _key(String cacheKey) => '$_prefix$cacheKey';

  static String _canonicalQuery(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    final pairs = <String>[];
    final keys = params.keys.toList()..sort();
    for (final key in keys) {
      final value = params[key];
      if (value == null) continue;
      if (value is Iterable) {
        for (final item in value) {
          if (item != null) {
            pairs.add(
              '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(item.toString())}',
            );
          }
        }
      } else {
        pairs.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}',
        );
      }
    }
    return pairs.join('&');
  }

  static Future<void> put(
    String cacheKey,
    dynamic data, {
    Duration? ttl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'ttlMs': (ttl ?? defaultTtl).inMilliseconds,
      'data': data,
    };
    await prefs.setString(_key(cacheKey), jsonEncode(entry));
  }

  static Future<dynamic> get(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(cacheKey));
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

  /// Clear all LocalCache entries (logout / session invalidate).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
