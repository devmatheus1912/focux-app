import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/friendly_error.dart';
import '../widgets/feedback_helper.dart';
import '../widgets/fx_loading.dart';
import 'excluir_conta_sheet.dart';

const excluirContaPath = '/api/lgpd/me/delete';
const excluirContaCodigoPath = '/api/lgpd/me/delete/codigo';

/// Corpo do DELETE: senha ou código do e-mail (conta Google/Apple sem senha).
Map<String, String> excluirContaBody({
  required String senha,
  required String codigo,
  required String confirmacao,
  required bool usarCodigo,
}) {
  return {
    if (usarCodigo) 'codigoEmail': codigo.trim() else 'senha': senha,
    'confirmacao': confirmacao.trim(),
  };
}

/// Valida antes de ir à rede. Retorna a mensagem de erro ou `null`.
String? excluirContaErroLocal(
  S l10n, {
  required String senha,
  required String codigo,
  required String confirmacao,
  required bool usarCodigo,
}) {
  if (confirmacao.trim() != 'EXCLUIR') return l10n.excluirContaDigiteExcluir;
  final credencial = usarCodigo ? codigo.trim() : senha;
  if (credencial.isEmpty) return l10n.excluirContaInformeCredencial;
  return null;
}

/// Folha de exclusão de conta em passos, com carregamento bloqueante durante o
/// DELETE. [aposExcluir] roda só se o backend confirmar a exclusão.
Future<void> excluirContaFlow(
  BuildContext context, {
  required Dio dio,
  required ExcluirContaPapel papel,
  required Future<void> Function() aposExcluir,
  bool avisoAssinatura = false,
}) async {
  final l10n = S.of(context);
  final credencial = await showExcluirContaSheet(
    context,
    dio: dio,
    papel: papel,
    avisoAssinatura: avisoAssinatura,
  );
  if (credencial == null || !context.mounted) return;
  final senha = credencial.senha;
  final codigo = credencial.codigo;
  final confirmacao = credencial.confirmacao;
  final usarCodigo = credencial.usarCodigo;

  final erro = excluirContaErroLocal(
    l10n,
    senha: senha,
    codigo: codigo,
    confirmacao: confirmacao,
    usarCodigo: usarCodigo,
  );
  if (erro != null) {
    FeedbackHelper.showError(context, erro);
    return;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(dimension: 24, child: FxLoading(size: 24)),
              const SizedBox(width: 16),
              Flexible(child: Text(l10n.excluirContaExcluindo)),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    await dio.delete<void>(
      excluirContaPath,
      data: excluirContaBody(
        senha: senha,
        codigo: codigo,
        confirmacao: confirmacao,
        usarCodigo: usarCodigo,
      ),
      options: Options(extra: {'fxNoRetry': true, 'fxNoInvalidate': true}),
    );
  } catch (e) {
    navigator.pop();
    if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    return;
  }
  navigator.pop();
  await aposExcluir();
}
