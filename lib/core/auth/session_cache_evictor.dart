import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/alunos/providers/alunos_provider.dart';
import '../../features/chat/screens/chat_inbox_screen.dart';
import '../../features/dashboard/providers/aderencia_provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/perfil/providers/perfil_provider.dart';

/// Limpa caches Riverpod ligados ao tenant após logout ou novo login.
void invalidateSessionUserCaches(WidgetRef ref) {
  ref.invalidate(dashboardHomeProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(commandCenterProvider);
  ref.invalidate(perfilProvider);
  ref.invalidate(alunosHomeProvider);
  ref.invalidate(alunosProvider);
  ref.invalidate(chatInboxProvider);
  ref.invalidate(aderenciaTop3Provider);
}
