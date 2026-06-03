import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/alunos/providers/aluno_followup_provider.dart';
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
  ref.invalidate(dashboardFinanceiroProvider);
  ref.invalidate(perfilProvider);
  ref.invalidate(alunosProvider);
  ref.invalidate(alunosStatsProvider);
  ref.invalidate(chatInboxProvider);
  ref.invalidate(aderenciaTop3Provider);
}
