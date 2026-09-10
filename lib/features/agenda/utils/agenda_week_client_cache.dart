import '../data/agenda_repository.dart';

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
