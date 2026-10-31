import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/br_phone.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/widgets/feedback_helper.dart';


String formatRiscoNivel(String? raw) {
  final value = (raw ?? '').trim().toUpperCase();
  if (value.isEmpty) return '—';
  return switch (value) {
    'ALTO' || 'HIGH' => 'Alto',
    'MEDIO' || 'MÉDIO' || 'MEDIUM' => 'Médio',
    'BAIXO' || 'LOW' => 'Baixo',
    _ => raw!.trim()[0].toUpperCase() + raw.trim().substring(1).toLowerCase(),
  };
}

/// Máscara de e-mail para listas (privacidade). Detalhe do aluno mantém o valor completo.
String maskEmailForList(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return '—';
  final at = trimmed.indexOf('@');
  if (at <= 0) return trimmed;
  final local = trimmed.substring(0, at);
  final domain = trimmed.substring(at + 1);
  if (domain.isEmpty) return trimmed;
  final visible = local.isEmpty ? '*' : local[0];
  return '$visible***@$domain';
}

Future<void> openAlunoWhatsappOutreach(
  BuildContext context, {
  required String displayName,
  required String whatsappNumber,
  required bool emRisco,
  String? message,
}) async {
  HapticFeedback.selectionClick();
  final firstName = displayName.split(' ').first;
  final mensagem =
      message ??
      (emRisco
          ? 'Oi $firstName, tudo bem? Vi que faz um tempo sem registrarmos treino. Posso te ajudar a retomar a rotina?'
          : 'Oi $firstName, tudo bem? Passando para alinhar sua mensalidade pendente.');
  final uri = BrPhone.whatsAppUri(whatsappNumber, text: mensagem);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  await copySensitiveToClipboard(mensagem);
  if (context.mounted) {
    FeedbackHelper.showSuccess(
      context,
      'Mensagem copiada para a área de transferência',
    );
  }
}
