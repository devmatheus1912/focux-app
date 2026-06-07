import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local do modo foco na aba Operação (por aluno).
class AlunoOperacaoFocusStore {
  static String _key(int alunoId) => 'aluno360_operacao_focus_$alunoId';

  /// Null when the personal never toggled focus for this aluno (auto-default applies).
  static Future<bool?> loadExplicit(int alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key(alunoId))) return null;
    return prefs.getBool(_key(alunoId));
  }

  static Future<void> saveExplicit(int alunoId, bool focusMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(alunoId), focusMode);
  }
}
