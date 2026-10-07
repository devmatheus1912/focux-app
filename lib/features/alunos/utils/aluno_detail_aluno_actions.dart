import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../widgets/aluno_delete_confirm_sheet.dart';
import '../widgets/aluno_link_ativacao_sheet.dart';
import 'aluno_status.dart';

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
      // Antes do pop: o ref da ficha morre com a rota.
      invalidateAlunosCaches(ref);
      FeedbackHelper.showSuccess(context, 'Aluno excluído.');
      safePopOrGo(context, '/alunos');
    }
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}

Future<void> confirmarAlteracaoStatusAlunoDetail(
  BuildContext context,
  WidgetRef ref,
  Aluno aluno,
  String novoStatus,
) async {
  final confirm = await showFxConfirmSheet(
    context,
    title: alunoStatusConfirmTitle(novoStatus, aluno.nome),
    message: alunoStatusConfirmMessage(novoStatus),
    icon: alunoStatusIcon(novoStatus),
    confirmIcon: alunoStatusIcon(novoStatus),
    confirmLabel: alunoStatusConfirmLabel(novoStatus),
    destructive: novoStatus == AlunoStatus.bloqueado,
  );
  if (!confirm || !context.mounted) return;
  try {
    await AlunoRepository(
      ref.read(apiClientProvider),
    ).atualizarStatusLote([aluno.id], novoStatus);
    if (!context.mounted) return;
    invalidateAlunosCaches(ref);
    FeedbackHelper.showSuccess(
      context,
      alunoStatusAlteradoMessage(
        novoStatus,
        nome: aluno.nome,
        genero: aluno.genero,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
    return;
  }
  // Falha do refetch aparece no estado da ficha, não como erro do status.
  try {
    await invalidateAluno360Providers(ref, aluno.id);
  } catch (_) {}
}

Future<void> confirmarReenviarLinkAlunoDetail(
  BuildContext context,
  WidgetRef ref,
  Aluno aluno,
) async {
  final s = S.of(context);
  final confirm = await showFxConfirmSheet(
    context,
    title: s.alunoReenviarLinkTitulo,
    message: s.alunoReenviarLinkTexto(aluno.nome),
    icon: Icons.link_rounded,
    confirmIcon: Icons.link_rounded,
    confirmLabel: s.alunoReenviarLinkConfirma,
  );
  if (!confirm || !context.mounted) return;

  try {
    final link = await AlunoRepository(
      ref.read(apiClientProvider),
    ).gerarLinkAtivacao(aluno.id);
    if (!context.mounted) return;
    await showAlunoLinkAtivacaoSheet(
      context: context,
      nome: aluno.nome,
      link: link,
      whatsapp: aluno.whatsapp,
      reenvio: true,
    );
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: s.alunoReenviarLinkErro),
      );
    }
  }
}
