import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueuedRequest {
  final String path;
  final String method;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;

  QueuedRequest({
    required this.path,
    required this.method,
    this.data,
    this.queryParameters,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'method': method,
        'data': data,
        'queryParameters': queryParameters,
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        path: json['path'],
        method: json['method'],
        data: json['data'],
        queryParameters: json['queryParameters'],
      );
}

class OfflineSyncService {
  static const _queueKey = 'offline_outbox_queue';

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

  /// Try to sync all pending requests using the provided Dio instance
  static Future<void> syncPendingRequests(Dio dio) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_queueKey);
    if (queueStr == null) return;

    final List<dynamic> queueList = jsonDecode(queueStr);
    if (queueList.isEmpty) return;

    List<dynamic> remainingList = [];

    for (var item in queueList) {
      try {
        final req = QueuedRequest.fromJson(item);
        await dio.request(
          req.path,
          data: req.data,
          queryParameters: req.queryParameters,
          options: Options(method: req.method),
        );
      } catch (e) {
        // Se falhar de novo (por conexão), mantém na fila
        remainingList.add(item);
      }
    }

    if (remainingList.isEmpty) {
      await prefs.remove(_queueKey);
    } else {
      await prefs.setString(_queueKey, jsonEncode(remainingList));
    }
  }
}
