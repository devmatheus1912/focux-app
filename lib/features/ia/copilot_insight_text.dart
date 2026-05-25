import 'dart:convert';

const copilotInsightFallback =
    'Não foi possível exibir o texto desta recomendação. Toque em Atualizar insights.';

String copilotInsightTitulo(Map<String, dynamic> insight, int index) {
  final raw = (insight['titulo'] ?? insight['title'] ?? '').toString().trim();
  if (raw.isEmpty ||
      RegExp(r'^insight\s+\d+$', caseSensitive: false).hasMatch(raw)) {
    return 'Recomendação ${index + 1}';
  }
  return raw;
}

String copilotInsightTipo(Map<String, dynamic> insight) {
  final direct =
      (insight['tipo'] ?? insight['categoria'] ?? '').toString().trim();
  if (direct.isNotEmpty) return direct;
  return _tipoFromJsonBlob(_insightRawText(insight)) ?? '';
}

String copilotInsightDetalhe(Map<String, dynamic> insight) {
  for (final raw in _insightTextCandidates(insight)) {
    final parsed = _unwrapCopilotInsightText(raw);
    if (parsed != null && parsed.isNotEmpty && !_looksLikeJson(parsed)) {
      return parsed;
    }
  }
  return copilotInsightFallback;
}

List<String> _insightTextCandidates(Map<String, dynamic> insight) {
  return [
    insight['detalhe'],
    insight['descricao'],
    insight['descrição'],
    insight['mensagem'],
    insight['texto'],
    insight['resumo'],
  ].map((v) => v?.toString().trim() ?? '').where((s) => s.isNotEmpty).toList();
}

String _insightRawText(Map<String, dynamic> insight) {
  final parts = _insightTextCandidates(insight);
  return parts.isEmpty ? '' : parts.first;
}

bool _looksLikeJson(String text) {
  final t = text.trimLeft();
  return t.startsWith('{') || t.startsWith('[');
}

String? _unwrapCopilotInsightText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  if (!_looksLikeJson(trimmed)) return trimmed;

  try {
    final decoded = jsonDecode(trimmed);
    return _extractTextFromDecoded(decoded);
  } catch (_) {
    final match = RegExp(
      r'"(?:descricao|descrição|mensagem|detalhe)"\s*:\s*"((?:\\.|[^"\\])*)"',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      final extracted = _unescapeJsonString(match.group(1)!);
      if (extracted.isNotEmpty) return extracted;
    }
    return null;
  }
}

String? _extractTextFromDecoded(dynamic decoded) {
  if (decoded is String) {
    final t = decoded.trim();
    return t.isEmpty || _looksLikeJson(t) ? null : t;
  }
  if (decoded is Map) {
    final map = Map<String, dynamic>.from(decoded);
    for (final key in [
      'descricao',
      'descrição',
      'detalhe',
      'mensagem',
      'texto',
      'resumo',
    ]) {
      final value = map[key];
      if (value == null) continue;
      final nested = _extractTextFromDecoded(value);
      if (nested != null && nested.isNotEmpty) return nested;
    }
    final nestedInsights = map['insights'];
    if (nestedInsights is List) {
      for (final item in nestedInsights) {
        final nested = _extractTextFromDecoded(item);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
  }
  if (decoded is List) {
    for (final item in decoded) {
      final nested = _extractTextFromDecoded(item);
      if (nested != null && nested.isNotEmpty) return nested;
    }
  }
  return null;
}

String? _tipoFromJsonBlob(String text) {
  if (!_looksLikeJson(text)) return null;
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final direct = (map['tipo'] ?? map['categoria'] ?? '').toString().trim();
      if (direct.isNotEmpty) return direct;
      final list = map['insights'];
      if (list is List && list.isNotEmpty && list.first is Map) {
        final first = Map<String, dynamic>.from(list.first as Map);
        return (first['tipo'] ?? first['categoria'] ?? '').toString().trim();
      }
    }
  } catch (_) {
    final match = RegExp(
      r'"(?:tipo|categoria)"\s*:\s*"((?:\\.|[^"\\])*)"',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) return _unescapeJsonString(match.group(1)!);
  }
  return null;
}

String _unescapeJsonString(String value) {
  try {
    return jsonDecode('"$value"') as String;
  } catch (_) {
    return value.replaceAll(r'\n', '\n').replaceAll(r'\"', '"');
  }
}
