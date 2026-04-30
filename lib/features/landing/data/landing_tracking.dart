import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';

String landingRegisterPath(
  String slug,
  String? trackingId, {
  required String source,
}) {
  final track = trackingId?.trim();
  final params = {
    'p': slug,
    'src': source,
    if (track != null && track.isNotEmpty) 'track': track,
  };
  return Uri(path: '/register/aluno', queryParameters: params).toString();
}

void trackLandingEvent({
  required String slug,
  required String eventType,
  String? source,
  String? trackingId,
  String? path,
}) {
  unawaited(_trackLandingEvent(
    slug: slug,
    eventType: eventType,
    source: source,
    trackingId: trackingId,
    path: path,
  ));
}

Future<void> _trackLandingEvent({
  required String slug,
  required String eventType,
  String? source,
  String? trackingId,
  String? path,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('${Env.apiUrl}/api/public/personal/$slug/eventos'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'eventType': eventType,
            if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
            if (trackingId != null && trackingId.trim().isNotEmpty)
              'trackingId': trackingId.trim(),
            if (path != null && path.trim().isNotEmpty) 'path': path.trim(),
          }),
        )
        .timeout(const Duration(seconds: 3));
    if (kDebugMode && response.statusCode >= 400) {
      debugPrint('Landing tracking ignored: ${response.statusCode}');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Landing tracking ignored: $e');
    }
  }
}
