import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../widgets/aluno_delete_confirm_sheet.dart';

String alunoDeleteConfirmToken(String nome) {
  final trimmed = nome.trim();
  if (trimmed.isEmpty) return 'aluno';
  if (trimmed.length <= 3) return trimmed.toLowerCase();
  return trimmed.substring(0, 3).toLowerCase();
}

Future<void> confirmarExclusaoAlunoDetail(
  BuildContext context,
  WidgetRef ref,
  Aluno aluno,
) async {
  final confirmToken = alunoDeleteConfirmToken(aluno.nome);
  final confirm = await showFxHomeSheet<bool>(
    context,
    builder:
        (ctx) =>
            AlunoDeleteConfirmSheet(aluno: aluno, confirmToken: confirmToken),
  );
  if (confirm != true || !context.mounted) return;
  try {
    await AlunoRepository(ref.read(apiClientProvider)).excluirAluno(aluno.id);
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, 'Aluno excluído.');
      safePopOrGo(context, '/alunos');
    }
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}

Future<void> confirmarGerarSenhaAlunoDetail(
  BuildContext context,
  WidgetRef ref,
  Aluno aluno,
) async {
  final confirm = await showFxConfirmSheet(
    context,
    title: 'Gerar nova senha?',
    message:
        'A senha atual de ${aluno.nome} deixará de funcionar. Gere apenas se o aluno esqueceu a senha ou precisa recuperar acesso.',
    icon: Icons.key_rounded,
    confirmIcon: Icons.key_rounded,
    confirmLabel: 'Gerar senha',
  );
  if (!confirm || !context.mounted) return;

  try {
    final senha = await AlunoRepository(
      ref.read(apiClientProvider),
    ).gerarSenhaProvisoria(aluno.id);
    ref.invalidate(alunoProvider(aluno.id));
    if (context.mounted) {
      showAlunoNovaSenhaProvisoriaSheet(context, aluno, senha);
    }
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível gerar senha.'),
      );
    }
  }
}

void showAlunoNovaSenhaProvisoriaSheet(
  BuildContext context,
  Aluno aluno,
  String senha,
) {
  final chrome = ShellChrome.of(context);
  final primary = Theme.of(context).colorScheme.primary;
  final ink = chrome.ink;
  final mute = chrome.mute;
  final line = chrome.line;
  final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
  final hasWhatsapp = whatsappNumber.isNotEmpty;
  final mensagem = alunoSenhaProvisoriaMessage(aluno, senha);
  final firstName =
      aluno.nome.trim().isEmpty
          ? 'o aluno'
          : aluno.nome.trim().split(RegExp(r'\s+')).first;

  showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return FxHomeSheetScaffold(
        isDark: isDark,
        leading: Icon(Icons.key_rounded, color: primary, size: 18),
        title: 'Senha provisória gerada',
        subtitle:
            'A senha anterior de $firstName não vale mais. '
            'No primeiro acesso, peça para definir uma senha nova.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line.withValues(alpha: 0.55)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  children: [
                    Text(
                      'Código de acesso',
                      style: Aluno360Layout.metaStyle(ctx).copyWith(
                        color: mute,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      senha,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Compartilhe só com $firstName.',
                      textAlign: TextAlign.center,
                      style: Aluno360Layout.captionStyle(ctx).copyWith(
                        color: mute,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TokensStrip.s4),
            FilledButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                if (hasWhatsapp) {
                  final uri = Uri.parse(
                    'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(mensagem)}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    return;
                  }
                }
                await copySensitiveToClipboard(mensagem);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  FeedbackHelper.showSuccess(
                    context,
                    hasWhatsapp
                        ? 'Convite copiado. Abra o WhatsApp e envie ao aluno.'
                        : 'Convite copiado.',
                  );
                }
              },
              icon: Icon(
                hasWhatsapp ? Icons.send_rounded : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(hasWhatsapp ? 'Enviar no WhatsApp' : 'Copiar convite'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            if (hasWhatsapp) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await copySensitiveToClipboard(mensagem);
                  HapticFeedback.mediumImpact();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    FeedbackHelper.showSuccess(context, 'Convite copiado.');
                  }
                },
                icon: Icon(Icons.copy_rounded, size: 18, color: ink),
                label: Text(
                  'Copiar convite',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: line.withValues(alpha: 0.75)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Fechar',
                style: TextStyle(color: mute, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String alunoSenhaProvisoriaMessage(Aluno aluno, String senha) {
  final primeiroNome =
      aluno.nome.trim().isEmpty
          ? 'tudo bem'
          : aluno.nome.trim().split(RegExp(r'\s+')).first;
  return 'Olá $primeiroNome! Redefinimos seu acesso ao Focux.\n\n'
      'Entre com seu e-mail: ${aluno.email}\n'
      'Senha provisória: $senha\n\n'
      'No primeiro acesso, troque por uma senha sua.';
}
