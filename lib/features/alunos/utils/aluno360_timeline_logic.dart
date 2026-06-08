import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
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

  return sanitizeCopilotIaLanguage(text);
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

/// Chat events use sender chip instead of priority badge.
bool timeline360ShouldShowPriorityBadge({required String kind}) {
  return kind != 'Chat';
}

/// Sender label for chat timeline rows.
String? timeline360SenderChipLabel({
  required String kind,
  required String meta,
  required String title,
}) {
  if (kind != 'Chat') return null;
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
