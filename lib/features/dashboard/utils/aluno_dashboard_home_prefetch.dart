import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_provider.dart';

/// Warms the aluno Home BFF (ClientCache) before navigation.
Future<void> prefetchAlunoDashboardHome(WidgetRef ref) async {
  try {
    await ref.read(alunoDashboardHomeProvider.future);
  } catch (_) {
    // Best-effort.
  }
}
