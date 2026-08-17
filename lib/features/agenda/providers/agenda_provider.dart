import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(ref.read(apiClientProvider)),
);

final agendaHomeProvider = FutureProvider<AgendaHomeBundle>((ref) async {
  return ref.read(agendaRepositoryProvider).getHome();
});

void invalidateAgendaCaches(WidgetRef ref) {
  ref.invalidate(agendaHomeProvider);
}
