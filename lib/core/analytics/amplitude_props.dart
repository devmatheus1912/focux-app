/// Props que podem sair do app para o Amplitude (LGPD).
///
/// Ficam só números, booleanos e textos curtos de categoria. IDs (aluno,
/// treino, transação), códigos de convite e textos com cara de PII não saem.
Map<String, Object> amplitudeSafeProps(Map<String, Object?>? props) {
  if (props == null || props.isEmpty) return const {};
  final out = <String, Object>{};
  for (final entry in props.entries) {
    final key = entry.key;
    if (_isBlockedKey(key)) continue;
    final value = entry.value;
    if (value is bool || value is num) {
      out[key] = value!;
    } else if (value is String) {
      final safe = _safeString(value);
      if (safe != null) out[key] = safe;
    }
  }
  return out;
}

final RegExp _idKey = RegExp(r'(^id$|_ids?$|Ids?$)');
const Set<String> _blockedKeys = {'codigo', 'code', 'token', 'email'};

/// Termina em `_id` mas guarda nome de plano, não identifica pessoa.
const Set<String> _allowedIdKeys = {'plan_id'};

bool _isBlockedKey(String key) {
  if (_allowedIdKeys.contains(key)) return false;
  return _idKey.hasMatch(key) || _blockedKeys.contains(key.toLowerCase());
}

final RegExp _numericPathSegment = RegExp(r'/\d+(?=/|$|\?)');
final RegExp _longDigits = RegExp(r'\d{6,}');

String? _safeString(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.length > 80) return null;
  if (value.contains('@')) return null;
  final normalized = value.replaceAll(_numericPathSegment, '/:id');
  if (_longDigits.hasMatch(normalized)) return null;
  return normalized;
}
