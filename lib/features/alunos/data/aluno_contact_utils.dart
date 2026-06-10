import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/feedback_helper.dart';
import 'aluno_followup_store.dart';
import 'aluno_repository.dart';

/// Whether this aluno should appear in "Precisa contato hoje".
bool alunoPrecisaContatoHoje(
  Aluno aluno, {
  DateTime? snoozedUntil,
  DateTime? followUpDate,
  DateTime? now,
  int diasSemTreinoLimite = AlunoFollowUpStore.diasSemTreinoLimite,
}) {
  if (aluno.status != 'ATIVO') return false;

  final clock = now ?? DateTime.now();
  final snooze = snoozedUntil ?? aluno.snoozedUntilDate;
  if (snooze != null && snooze.isAfter(clock)) {
    return false;
  }

  final followDate = followUpDate ?? aluno.followUpDate;
  if (followDate != null) {
    final today = DateTime(clock.year, clock.month, clock.day);
    final followDay = DateTime(
      followDate.year,
      followDate.month,
      followDate.day,
    );
    if (!followDay.isAfter(today)) return true;
  }

  if (aluno.emRisco) return true;
  if (aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE') {
    return true;
  }
  final dias = aluno.diasSemTreino ?? 0;
  if (dias >= diasSemTreinoLimite) return true;
  return false;
}

int alunoContatoPriorityBoost(
  Aluno aluno, {
  DateTime? now,
  int diasSemTreinoLimite = AlunoFollowUpStore.diasSemTreinoLimite,
}) {
  if (!alunoPrecisaContatoHoje(
    aluno,
    now: now,
    diasSemTreinoLimite: diasSemTreinoLimite,
  )) {
    return 0;
  }
  var boost = 4;
  final followDate = aluno.followUpDate;
  if (followDate != null) {
    final today = DateTime(now?.year ?? DateTime.now().year,
        now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
    final followDay = DateTime(
      followDate.year,
      followDate.month,
      followDate.day,
    );
    if (!followDay.isAfter(today)) boost += 3;
  }
  return boost;
}

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

String formatProximoContato(Aluno aluno) {
  final date = aluno.followUpDate;
  if (date == null) return 'Sem data';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m';
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
}) async {
  HapticFeedback.selectionClick();
  final firstName = displayName.split(' ').first;
  final mensagem =
      emRisco
          ? 'Oi $firstName, tudo bem? Vi que faz um tempo sem registrarmos treino. Posso te ajudar a retomar a rotina?'
          : 'Oi $firstName, tudo bem? Passando para alinhar sua mensalidade pendente.';
  final uri = Uri.parse(
    'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(mensagem)}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  await Clipboard.setData(ClipboardData(text: mensagem));
  if (context.mounted) {
    FeedbackHelper.showSuccess(context, 'Mensagem copiada para a área de transferência');
  }
}
