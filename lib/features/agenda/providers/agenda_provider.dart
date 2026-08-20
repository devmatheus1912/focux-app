import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(ref.read(apiClientProvider)),
);

final agendaHomeProvider = FutureProvider<AgendaHomeBundle>((ref) async {
  return ref.read(agendaRepositoryProvider).getHome();
});

class AgendaWeekClientCache {
  AgendaWeekClientCache._();

  static const ttl = Duration(seconds: 45);
  static final _items = <String, ({DateTime at, List<Agendamento> data})>{};

  static List<Agendamento>? get(String isoMonday) {
    final hit = _items[isoMonday];
    if (hit == null) return null;
    if (DateTime.now().difference(hit.at) > ttl) {
      _items.remove(isoMonday);
      return null;
    }
    return hit.data;
  }

  static void put(String isoMonday, List<Agendamento> data) {
    _items[isoMonday] = (at: DateTime.now(), data: data);
  }

  static void clear() => _items.clear();
}

void invalidateAgendaCaches(WidgetRef ref) {
  AgendaWeekClientCache.clear();
  ref.invalidate(agendaHomeProvider);
}
