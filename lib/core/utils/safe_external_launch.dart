import 'package:url_launcher/url_launcher.dart';

/// Só http(s) — bloqueia `javascript:`, `intent:`, `file:`, etc.
bool isSafeHttpUrl(Uri uri) =>
    uri.scheme == 'http' || uri.scheme == 'https';

/// Abre URL externa só se for http(s). Retorna `false` se bloqueada ou falhar.
Future<bool> launchSafeHttpUrl(
  String url, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !isSafeHttpUrl(uri)) return false;
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: mode);
}
