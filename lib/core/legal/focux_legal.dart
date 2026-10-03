import 'package:url_launcher/url_launcher.dart';

/// URLs oficiais — mesmas páginas usadas no cadastro e no perfil.
abstract class FocuxLegal {
  FocuxLegal._();

  static const String termsUrl = 'https://focuxpersonal.com/termos';
  static const String privacyUrl = 'https://focuxpersonal.com/privacidade';
  static const String supportUrl = 'https://focuxpersonal.com/suporte';
  static const String deleteAccountUrl =
      'https://focuxpersonal.com/excluir-conta';

  /// Versão dos docs enviada em `POST /api/lgpd/me/consent`.
  static const String consentDocumentVersion = '2026-09';

  static Future<bool> openTerms() => _open(termsUrl);

  static Future<bool> openPrivacy() => _open(privacyUrl);

  static Future<bool> openSupport() => _open(supportUrl);

  static Future<bool> openDeleteAccount() => _open(deleteAccountUrl);

  static Future<bool> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
