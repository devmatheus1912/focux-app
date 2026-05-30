import 'package:shared_preferences/shared_preferences.dart';

/// Máximo 1 modal de upgrade por gatilho a cada 24h.
class UpgradePromptCooldown {
  UpgradePromptCooldown._();

  static const _prefix = 'focux_upgrade_prompt_shown_';
  static const _dismissPrefix = 'focux_upgrade_prompt_never_';
  static const _cooldownMs = 24 * 60 * 60 * 1000;

  static String keyFor({String? capability, required String featureName}) {
    final cap = (capability ?? featureName).trim().toLowerCase();
    return cap.isEmpty ? 'generic' : cap;
  }

  static Future<bool> shouldShow(String triggerKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_dismissPrefix$triggerKey') == true) return false;
    final last = prefs.getInt('$_prefix$triggerKey');
    if (last == null) return true;
    return DateTime.now().millisecondsSinceEpoch - last > _cooldownMs;
  }

  static Future<void> markShown(String triggerKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_prefix$triggerKey',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> dismissForever(String triggerKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dismissPrefix$triggerKey', true);
  }
}
