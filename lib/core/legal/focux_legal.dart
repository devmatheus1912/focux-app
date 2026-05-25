import 'package:url_launcher/url_launcher.dart';

/// URLs oficiais — mesmas páginas usadas no cadastro e no perfil.
abstract class FocuxLegal {
  FocuxLegal._();

  static const String termsUrl =
      'https://focux-backend-production.up.railway.app/termos.html';
  static const String privacyUrl =
      'https://focux-backend-production.up.railway.app/privacidade.html';

  static Future<bool> openTerms() => _open(termsUrl);

  static Future<bool> openPrivacy() => _open(privacyUrl);

  static Future<bool> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
