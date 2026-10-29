import 'package:shared_preferences/shared_preferences.dart';

/// Meta diária de passos: 8.000 por padrão, ajustável pelo aluno neste
/// aparelho (não vai para o servidor).
abstract final class SaudeMetaPassos {
  SaudeMetaPassos._();

  static const padrao = 8000;
  static const minimo = 4000;
  static const maximo = 20000;
  static const passo = 500;
  static const _key = 'saude_meta_passos';

  /// Limita ao intervalo e arredonda para o passo de 500.
  static int ajustar(int valor) {
    final arredondado = (valor / passo).round() * passo;
    return arredondado.clamp(minimo, maximo);
  }

  static Future<int> ler() async {
    final prefs = await SharedPreferences.getInstance();
    return ajustar(prefs.getInt(_key) ?? padrao);
  }

  static Future<void> salvar(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, ajustar(valor));
  }
}
