import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local do modo foco na aba Operação (por aluno).
class AlunoOperacaoFocusStore {
  static String _key(int alunoId) => 'aluno360_operacao_focus_$alunoId';

  static Future<bool> load(int alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(alunoId)) ?? false;
  }

  static Future<void> save(int alunoId, bool focusMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(alunoId), focusMode);
  }
}
