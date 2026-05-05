import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  void track(String event, [Map<String, Object?> props = const {}]) {
    debugPrint('[analytics] $event $props');
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);
