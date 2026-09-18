import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_provider.dart';

/// Warms the Home BFF before navigation so Hoje paints from a single round-trip.
Future<void> prefetchPersonalDashboardHome(WidgetRef ref) async {
  try {
    await ref.read(dashboardHomeProvider.future);
  } catch (_) {
    // Best-effort — Home ainda faz o fetch se falhar.
  }
}
