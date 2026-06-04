import '../../../core/config/env.dart';

/// Resolves aluno photo URLs (absolute or API-relative paths).
String? resolveAlunoPhotoUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;

  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) return raw;

  final base =
      Env.apiUrl.endsWith('/')
          ? Env.apiUrl.substring(0, Env.apiUrl.length - 1)
          : Env.apiUrl;
  final path = raw.startsWith('/') ? raw : '/$raw';
  return '$base$path';
}
