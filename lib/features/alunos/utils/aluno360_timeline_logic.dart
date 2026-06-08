import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../chat/data/chat_text_formatter.dart';
import 'aluno360_copilot_logic.dart';

/// Normalizes timeline copy to PT-BR and fixes legacy encoding leaks.
String sanitizeTimeline360Copy(String? raw) {
  if (raw == null) return '';
  var text = raw.trim();
  if (text.isEmpty) return '';

  text = text.replaceFirst(RegExp(r'^!\s*'), '');

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
  text = text.replaceAll(
    RegExp(r'precisa de uma ação humana', caseSensitive: false),
    'precisa de atenção',
  );

  text = sanitizeCopilotIaLanguage(text);
  text = normalizeChatText(text);
  text = timeline360CollapseCopilotTemplate(text);

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
  text = text.replaceAllMapped(
    RegExp(
      r'entre em contato com\s+(\S+)\s+para entender o motivo do afastamento\.?',
      caseSensitive: false,
    ),
    (m) => '${m[1]} sumiu do radar — manda um oi direto hoje.',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'contate\s+(\S+)\s+para entender (?:os motivos de sua |o motivo da )?inativid[^.]*\.?',
      caseSensitive: false,
    ),
    (m) => '${m[1]} sumiu do radar — manda um oi direto hoje.',
  );

  text = formatChatTextForDisplay(text);
  text = cleanCopilotText(text);
  return timeline360FinalizeCopy(text);
}

String timeline360RewriteCopilotExtractedAction(String action) {
  final trimmed = action.trim();
  if (trimmed.isEmpty) return trimmed;

  if (trimmed.toLowerCase().contains('sumiu do radar')) {
    return trimmed;
  }

  final contate = RegExp(
    r'^contate\s+(\S+)',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (contate != null) {
    return '${contate.group(1)} sumiu do radar — manda um oi direto hoje.';
  }
  return 'Próximo passo do plano: $trimmed';
}

String timeline360CollapseCopilotTemplate(String text) {
  var out = text.trim();
  if (out.isEmpty) return out;

  final copilotMatch = RegExp(
    r'^!?passei pelo seu acompanhamento[^.]*próximo passo[^:]*:\s*(.+)$',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(out);
  if (copilotMatch != null) {
    return timeline360RewriteCopilotExtractedAction(copilotMatch.group(1)!);
  }

  if (RegExp(
    r'^!?passei pelo seu acompanhamento',
    caseSensitive: false,
  ).hasMatch(out)) {
    return 'Acompanhamento registrado — revise o próximo passo no chat.';
  }
  return out;
}

String timeline360StripInactivitySuffixFragments(String text) {
  var out = text;
  out = out.replaceAll(
    RegExp(
      r'\.\s+para entender o motivo da inatividad[ée][^.]*\.?',
      caseSensitive: false,
    ),
    '.',
  );
  out = out.replaceAll(
    RegExp(
      r'\s+para entender o motivo da inatividad[ée][^.]*\.?',
      caseSensitive: false,
    ),
    '',
  );
  out = out.replaceAll(
    RegExp(r'\s+e verificar se há algum[^.]*\.?', caseSensitive: false),
    '',
  );
  return out;
}

String timeline360FinalizeCopy(String text) {
  var out = timeline360StripInactivitySuffixFragments(text.trim());
  out = out.replaceAll(RegExp(r'\s+para retomar\.?$', caseSensitive: false), '');
  out = out.replaceAll(RegExp(r'\.\s+para retomar\.?$', caseSensitive: false), '.');
  out = out.replaceAllMapped(
    RegExp(
      r'(ajusto o plano)\.?\s+para entender o motivo da inatividad[ée][^.]*\.?$',
      caseSensitive: false,
    ),
    (m) => '${m[1]}.',
  );
  out = out.replaceAll(RegExp(r'\s{2,}'), ' ');
  return out.trim();
}

/// Fingerprint para deduplicar previews de chat no FE (defensivo).
String timeline360ChatBodyFingerprint(String body) {
  final text = sanitizeTimeline360Copy(body).toLowerCase().replaceAll(
    RegExp(r'\s+'),
    ' ',
  ).trim();
  if (text.isEmpty) return '';
  if (text.startsWith('próximo passo do plano:') && text.contains('contate')) {
    return 'chat:recovery';
  }
  if (text.startsWith('próximo passo do plano:')) return text;
  if (text.contains('sumiu do radar') ||
      text.contains('notei sua ausência') ||
      text.contains('se afastou')) {
    return 'chat:recovery';
  }
  if (text.contains('acompanhamento registrado')) {
    return 'chat:copilot_acompanhamento';
  }
  return text.replaceAll(RegExp(r'[^a-z0-9áàâãéêíóôõúç\s]'), '').trim();
}

/// Dedupe chat rows by normalized body fingerprint (keeps first = most recent).
List<T> dedupeChatTimelineByFingerprint<T>(
  List<T> items, {
  required String Function(T item) kindOf,
  required String Function(T item) bodyOf,
}) {
  final out = <T>[];
  final seen = <String>{};
  for (final item in items) {
    if (kindOf(item) != 'Chat') {
      out.add(item);
      continue;
    }
    final fingerprint = timeline360ChatBodyFingerprint(bodyOf(item));
    if (fingerprint.isEmpty) {
      out.add(item);
      continue;
    }
    if (seen.contains(fingerprint)) continue;
    seen.add(fingerprint);
    out.add(item);
  }
  return out;
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
      text = stripped.trim();
      break;
    }
  }

  if (_isRecoveryBody(text)) {
    return _firstSentence(text);
  }
  return text;
}

bool _isRecoveryBody(String text) {
  final lower = text.toLowerCase();
  return lower.contains('sumiu do radar') ||
      lower.contains('me responde por aqui') ||
      lower.contains('notei sua ausência');
}

String _firstSentence(String text) {
  final match = RegExp(r'^[^.!?]+[.!?]').firstMatch(text.trim());
  if (match != null) return match.group(0)!.trim();
  return text.trim();
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

/// Sheet/modal title for a timeline item.
String timeline360SheetTitle({
  required String kind,
  required String title,
  required String meta,
}) {
  if (kind == 'Chat') {
    return timeline360KindHeader(kind: kind, title: title, meta: meta);
  }
  if (title.trim().isEmpty) return kind;
  return '$kind · ${title.trim()}';
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

bool timeline360BodyExpandable(
  String body, {
  String? kind,
  String? previewBody,
}) {
  final text = (previewBody ?? body).trim();
  final threshold = kind == 'Chat' ? 100 : 110;
  return text.length > threshold;
}

String timeline360ExpandLinkLabel({required String kind}) {
  return kind == 'Chat' ? 'Ler mensagem inteira' : 'Ver detalhes';
}

String formatTimeline360Date(DateTime? value) {
  if (value == null) return 'data não informada';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month às $hour:$minute';
}

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
