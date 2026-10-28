import 'package:shared_preferences/shared_preferences.dart';

/// Exercícios em que o aluno disse "sem carga" (peso do corpo): o app para de
/// perguntar a carga na primeira série deles.
class CheckinSemCargaStore {
  const CheckinSemCargaStore();

  static const _prefixo = 'checkin_sem_carga_v1_';

  Future<bool> semCarga(int treinoExercicioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefixo$treinoExercicioId') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> marcar(int treinoExercicioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefixo$treinoExercicioId', true);
    } catch (_) {}
  }
}
