import 'package:shared_preferences/shared_preferences.dart';

/// Lembra se o último login neste aparelho foi com Google ou Apple. A exclusão
/// de conta usa isso para pedir o código por e-mail em vez da senha.
const _chave = 'fx_ultimo_login_social';

Future<void> lembrarLoginSocial(bool social) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chave, social);
  } catch (_) {
    // Sem preferências (teste, armazenamento indisponível): a folha mostra a dica.
  }
}

Future<bool> entrouComLoginSocial() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chave) ?? false;
  } catch (_) {
    return false;
  }
}
