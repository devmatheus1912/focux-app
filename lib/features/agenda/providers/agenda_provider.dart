import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_week_client_cache.dart';

export '../utils/agenda_week_client_cache.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(ref.read(apiClientProvider)),
);

final agendaHomeProvider = FutureProvider<AgendaHomeBundle>((ref) async {
  return ref.read(agendaRepositoryProvider).getHome();
});

void invalidateAgendaCaches(WidgetRef ref) {
  AgendaWeekClientCache.clear();
  ref.invalidate(agendaHomeProvider);
}
