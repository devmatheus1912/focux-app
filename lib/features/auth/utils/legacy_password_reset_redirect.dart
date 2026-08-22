import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Links legados de e-mail usavam {@code #/resetar-senha?token=…}.
/// Flutter web (path strategy) ignora o fragmento — recupera o token e navega.
String? legacyPasswordResetPathFromUri(Uri uri) {
  final fragment = uri.fragment.trim();
  if (fragment.isEmpty) return null;

  final fragUri = Uri.tryParse(
    fragment.startsWith('/') ? fragment : '/$fragment',
  );
  if (fragUri == null) return null;

  final path = fragUri.path;
  if (path != '/resetar-senha' && !path.endsWith('/resetar-senha')) {
    return null;
  }
  final token = fragUri.queryParameters['token']?.trim();
  if (token == null || token.isEmpty) return null;
  return '/resetar-senha?token=${Uri.encodeQueryComponent(token)}';
}

/// Aplica o redirect legado uma vez no boot (web).
void applyLegacyPasswordResetRedirect(GoRouter router) {
  if (!kIsWeb) return;
  final path = legacyPasswordResetPathFromUri(Uri.base);
  if (path == null) return;
  // ignore: avoid_print
  debugPrint('[Focux] legacy hash reset → $path');
  router.go(path);
}
