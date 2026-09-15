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

/// Mutação que a fila desistiu de reenviar, guardada para a UI poder contar a
/// verdade depois de já ter respondido `202 queued` ao usuário.
class DroppedMutation {
  final String path;
  final String method;
  final int? statusCode;
  final int droppedAtMillis;

  const DroppedMutation({
    required this.path,
    required this.method,
    this.statusCode,
    required this.droppedAtMillis,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'method': method,
    'statusCode': statusCode,
    'droppedAtMillis': droppedAtMillis,
  };

  factory DroppedMutation.fromJson(Map<String, dynamic> json) =>
      DroppedMutation(
        path: json['path'] as String? ?? '',
        method: json['method'] as String? ?? '',
        statusCode: (json['statusCode'] as num?)?.toInt(),
        droppedAtMillis: (json['droppedAtMillis'] as num?)?.toInt() ?? 0,
      );
}

class OfflineSyncService {
  static const _queueKey = 'offline_outbox_queue';
  static const _droppedKey = 'offline_outbox_dropped';
  static const _maxAttempts = 8;
  static const _maxDropped = 20;

  /// 4xx que ainda valem nova tentativa. `409` entra porque o backend responde
  /// isso enquanto a *primeira* requisição com a mesma `Idempotency-Key` está
  /// em voo — a tentativa seguinte recebe o replay da resposta original.
  static const _retryableClientStatuses = {408, 409, 425, 429};

  /// Notificada quando uma mutação é descartada em definitivo. A UI liga aqui
  /// para avisar o usuário; sem ouvinte, o descarte fica só no registro
  /// persistido de [pendingDropped].
  static void Function(DroppedMutation)? onMutationDropped;

  /// Add a failed request to the queue (sem body sensível).
  ///
  /// Returns `true` only when the mutation is actually persisted. Callers that
  /// acknowledge the write as "queued" (HTTP 202) must check this — otherwise
  /// a sensitive path looks successful and is never retried.
  static Future<bool> enqueueRequest(RequestOptions options) async {
    if (isSensitivePath(options.path)) {
      return false;
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
    return true;
  }

  /// Mutations whose caller needs the real entity (or must not look successful
  /// if nothing was stored). Check-in numbered sets and finance writes are
  /// included: a fake 202 body is parsed as a series/fatura and loses data.
  static bool isSensitivePath(String path) {
    final p = path.toLowerCase();
    return p.contains('/chat') ||
        p.contains('/anamnese') ||
        p.contains('/health') ||
        p.contains('/lgpd') ||
        p.contains('/wallet') ||
        p.contains('/mensalidade') ||
        p.contains('/pagamento') ||
        p.contains('/financeiro') ||
        p.contains('/checkin') ||
        p.contains('/auth') ||
        p.contains('/alunos') ||
        p.contains('/leads') ||
        p.contains('/personal/perfil') ||
        p.contains('/ia') ||
        p.contains('/comunidade') ||
        p.contains('/fcm') ||
        p.contains('/upload');
  }

  static dynamic _sanitizeQueueData(String path, dynamic data) {
    if (data == null) return null;
    if (data is FormData) return null;
    if (isSensitivePath(path)) return null;
    return data;
  }

  /// Chamado na invalidação de sessão: leva o registro de descartes junto,
  /// porque ele descreve mutações do usuário que saiu.
  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    await prefs.remove(_droppedKey);
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
  ///
  /// Falha permanente (4xx que não seja [_retryableClientStatuses]) sai na
  /// primeira tentativa, sem gastar o backoff. Todo descarte, por limite de
  /// tentativas ou por ser permanente, fica registrado em [pendingDropped].
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
      } catch (error) {
        // Erro que nunca vai passar (validação, gate de plano, recurso que
        // sumiu) não ganha nova tentativa: reenviar 8 vezes só atrasa o
        // aviso ao usuário, que já recebeu `202 queued` como se tivesse dado
        // certo.
        final permanent = !_isRetryable(error);
        if (permanent || req.attempts + 1 >= _maxAttempts) {
          await _recordDropped(req, error);
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

  /// Na dúvida, retenta: só descarta o que dá para provar que é permanente.
  static bool _isRetryable(Object error) {
    if (error is! DioException) return true;
    final status = error.response?.statusCode;
    if (status == null) return true; // falha de transporte
    if (status >= 500) return true;
    if (status >= 400) return _retryableClientStatuses.contains(status);
    return true;
  }

  static Future<void> _recordDropped(QueuedRequest req, Object error) async {
    final dropped = DroppedMutation(
      path: req.path,
      method: req.method,
      statusCode: error is DioException ? error.response?.statusCode : null,
      droppedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_droppedKey);
      final list = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];
      list.add(dropped.toJson());
      // Mantém só as últimas: o registro serve para avisar, não para auditar.
      final trimmed =
          list.length > _maxDropped
              ? list.sublist(list.length - _maxDropped)
              : list;
      await prefs.setString(_droppedKey, jsonEncode(trimmed));
    } catch (_) {
      // Perder o registro não pode impedir a fila de seguir drenando.
    }
    try {
      onMutationDropped?.call(dropped);
    } catch (_) {}
  }

  /// Mutações que a fila desistiu de reenviar e que o usuário ainda não viu.
  static Future<List<DroppedMutation>> pendingDropped() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_droppedKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => DroppedMutation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clearDropped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_droppedKey);
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

  /// Remove entradas cujo cacheKey começa com [pathPrefix].
  static Future<void> invalidate(String pathPrefix) async {
    final prefs = await SharedPreferences.getInstance();
    final needle = '$_prefix$pathPrefix';
    final keys = prefs.getKeys().where((k) => k.startsWith(needle)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
