import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alunos/providers/alunos_provider.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../providers/dashboard_provider.dart';

/// Warms Home BFF + inbox before navigation so the dashboard paints faster.
void prefetchPersonalDashboardHome(WidgetRef ref) {
  unawaited(_ignoreErrors(ref.read(dashboardHomeProvider.future)));
  unawaited(_ignoreErrors(ref.read(alunosProvider.future)));
  unawaited(_ignoreErrors(ref.read(chatInboxProvider.future)));
}

Future<void> _ignoreErrors(Future<dynamic> future) async {
  try {
    await future;
  } catch (_) {}
}
