import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_provider.dart';

/// Warms the Home BFF before navigation so Hoje paints from a single round-trip.
void prefetchPersonalDashboardHome(WidgetRef ref) {
  unawaited(_ignoreErrors(ref.read(dashboardHomeProvider.future)));
}

Future<void> _ignoreErrors(Future<dynamic> future) async {
  try {
    await future;
  } catch (_) {}
}
