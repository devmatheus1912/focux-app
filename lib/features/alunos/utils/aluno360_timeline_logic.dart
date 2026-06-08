import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../chat/data/chat_text_formatter.dart';
import 'aluno360_copilot_logic.dart';

/// Normalizes timeline copy to PT-BR and fixes legacy encoding leaks.
String sanitizeTimeline360Copy(String? raw) {
  if (raw == null) return '';
  var text = raw.trim();
  if (text.isEmpty) return '';

  text = text.replaceAll(RegExp(r'\bacao\b', caseSensitive: false), 'ação');
  text = text.replaceAll(RegExp(r'\bevolucao\b', caseSensitive: false), 'evolução');
  text = text.replaceAll(RegExp(r'\besta\b', caseSensitive: false), 'está');

  const englishToPt = {
    'needs human action today: complete body map':
        'ainda não completou o mapa corporal — vale cobrar hoje.',
    'needs human action today': 'tem prioridade hoje',
    'needs human action': 'precisa de atenção',
    'human action today': 'prioridade hoje',
    'human action': 'atenção',
    'complete body map': 'completar mapa corporal',
    'body map': 'mapa corporal',
  };
  for (final entry in englishToPt.entries) {
    text = text.replaceAll(
      RegExp(RegExp.escape(entry.key), caseSensitive: false),
      entry.value,
    );
  }

  text = text.replaceAllMapped(
    RegExp(
      r'^(\S+)\s+precisa de uma ação humana hoje:\s*completar mapa corporal\.?$',
      caseSensitive: false,
    ),
    (m) => '${m[1]} ainda não completou o mapa corporal — vale cobrar hoje.',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'^(\S+)\s+precisa de uma ação humana hoje:\s*(.+?)\.?$',
      caseSensitive: false,
    ),
    (m) => '${m[1]} tem prioridade hoje: ${m[2]}.',
  );

  text = sanitizeCopilotIaLanguage(text);
  text = normalizeChatText(text);

  text = text.replaceAllMapped(
    RegExp(
      r'oi,\s*(\S+)\.\s*contate\s+\1\s+imediatamente(?:\s+para\s+retomar)?\.?',
      caseSensitive: false,
    ),
    (_) => 'Você sumiu do radar — me responde por aqui que eu ajusto o plano.',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'contate\s+(\S+)\s+imediatamente(?:\s+para\s+retomar)?\.?',
      caseSensitive: false,
    ),
    (m) => '${m[1]} sumiu do radar — manda um oi direto hoje.',
  );

  text = formatChatTextForDisplay(text);
  text = cleanCopilotText(text);
  return timeline360FinalizeCopy(text);
}

String timeline360FinalizeCopy(String text) {
  var out = text.trim();
  out = out.replaceAll(RegExp(r'\s+para retomar\.?$', caseSensitive: false), '');
  out = out.replaceAll(RegExp(r'\.\s+para retomar\.?$', caseSensitive: false), '.');
  out = out.replaceAll(RegExp(r'\s{2,}'), ' ');
  return out.trim();
}

/// Preview body for chat rows — drops redundant "Oi, {nome}." after kind header.
String timeline360ChatPreviewBody(
  String body, {
  String? alunoFirstName,
}) {
  var text = body.trim();
  if (text.isEmpty) return text;

  final patterns = <String>[];
  if (alunoFirstName != null && alunoFirstName.trim().isNotEmpty) {
    patterns.add('oi,\\s*${RegExp.escape(alunoFirstName.trim())}\\.?\\s*');
  }
  patterns.add(r'oi,\s*\S+\.?\s*');

  for (final pattern in patterns) {
    final stripped = text.replaceFirst(
      RegExp('^$pattern', caseSensitive: false),
      '',
    );
    if (stripped != text && stripped.trim().isNotEmpty) {
      return stripped.trim();
    }
  }
  return text;
}

/// Header label for timeline kind row (merges chat sender into one line).
String timeline360KindHeader({
  required String kind,
  required String title,
  required String meta,
}) {
  if (kind != 'Chat') return kind;
  final sender = timeline360SenderLabel(meta: meta, title: title);
  if (sender != null) return 'Chat · $sender';
  if (title.contains('·')) return title.trim();
  return kind;
}

/// Whether the title row adds information beyond the kind header.
bool timeline360ShowTitleRow({
  required String kind,
  required String title,
  required String meta,
}) {
  if (kind == 'Chat') return false;
  return title.trim().isNotEmpty;
}

/// Whether the meta line adds information beyond title/priority.
bool timeline360ShouldShowMetaChip({
  required String kind,
  required String meta,
  required String priority,
  required String title,
}) {
  if (kind == 'Chat') return false;
  final trimmed = meta.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed == priority.trim()) return false;
  final upper = trimmed.toUpperCase();
  if (upper == 'PERSONAL' || upper == 'ALUNO') return false;
  if (title.toLowerCase().contains(trimmed.toLowerCase())) return false;
  return true;
}

/// Chat events use sender in kind header — no priority badge.
bool timeline360ShouldShowPriorityBadge({required String kind}) {
  return kind != 'Chat';
}

String? timeline360SenderLabel({
  required String meta,
  required String title,
}) {
  final upper = meta.trim().toUpperCase();
  if (upper == 'PERSONAL') return 'Personal';
  if (upper == 'ALUNO') return 'Aluno';
  if (title.contains('Personal')) return 'Personal';
  if (title.contains('Aluno')) return 'Aluno';
  return null;
}

/// Semantic color for P0–P3 timeline priority tags.
Color timeline360PriorityColor(String? priority, {required Color primary}) {
  final value = (priority ?? '').trim().toUpperCase();
  if (value.startsWith('P0')) return EagleTokens.bad;
  if (value.startsWith('P1')) return EagleTokens.warn;
  if (value.startsWith('P2')) return primary;
  if (value.startsWith('P3')) return EagleTokens.good;
  return primary;
}

bool timeline360BodyExpandable(String body) => body.trim().length > 96;

bool timeline360HasFooterChips({
  required String kind,
  required String meta,
  required String priority,
  required String title,
}) {
  return timeline360ShouldShowPriorityBadge(kind: kind) ||
      timeline360ShouldShowMetaChip(
        kind: kind,
        meta: meta,
        priority: priority,
        title: title,
      );
}
