import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_week_client_cache.dart';

export '../utils/agenda_week_client_cache.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(ref.read(apiClientProvider)),
);

/// Agenda mudou (criar, remarcar, status, presença, excluir) ou foi recarregada
/// à força: cai a semana em cache e a Home do personal, que mostra a agenda do
/// dia e a ação "Preparar agenda". Sem isso o Hoje segue com o horário antigo.
void invalidateAgendaCaches(WidgetRef ref) {
  AgendaWeekClientCache.clear();
  invalidatePersonalDashboardHome(ref);
}
