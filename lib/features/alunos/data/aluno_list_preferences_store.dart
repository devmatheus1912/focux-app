import 'package:shared_preferences/shared_preferences.dart';

/// Preferências locais da lista de alunos (densidade, etc.).
class AlunoListPreferences {
  const AlunoListPreferences({this.compact = false});

  final bool compact;

  AlunoListPreferences copyWith({bool? compact}) {
    return AlunoListPreferences(compact: compact ?? this.compact);
  }
}

class AlunoListPreferencesStore {
  static const _compactKey = 'alunos_list_compact';

  static Future<AlunoListPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AlunoListPreferences(compact: prefs.getBool(_compactKey) ?? true);
  }

  static Future<void> saveCompact(bool compact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactKey, compact);
  }
}
