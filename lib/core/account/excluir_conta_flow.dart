import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/friendly_error.dart';
import '../widgets/feedback_helper.dart';
import '../widgets/fx_form_sheet.dart';
import '../widgets/fx_input_deco.dart';
import '../widgets/fx_keyboard_dismiss_scope.dart';
import '../widgets/fx_loading.dart';

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

/// Sheet de exclusão de conta com carregamento bloqueante durante o DELETE.
/// [aposExcluir] roda só se o backend confirmar a exclusão.
Future<void> excluirContaFlow(
  BuildContext context, {
  required Dio dio,
  required String subtitulo,
  required Future<void> Function() aposExcluir,
  bool avisoAssinatura = false,
}) async {
  final l10n = S.of(context);
  final senhaCtrl = TextEditingController();
  final codigoCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  var usarCodigo = false;

  final ok = await showFxFormSheet(
    context,
    title: 'Excluir conta',
    subtitle: avisoAssinatura
        ? '$subtitulo\n\n${l10n.excluirContaAvisoAssinatura}'
        : subtitulo,
    icon: Icons.delete_forever_outlined,
    confirmLabel: 'Excluir definitivamente',
    destructive: true,
    child: _ExcluirContaCampos(
      dio: dio,
      senhaCtrl: senhaCtrl,
      codigoCtrl: codigoCtrl,
      confirmCtrl: confirmCtrl,
      onModoChanged: (v) => usarCodigo = v,
    ),
  );

  final senha = senhaCtrl.text;
  final codigo = codigoCtrl.text;
  final confirmacao = confirmCtrl.text;
  senhaCtrl.dispose();
  codigoCtrl.dispose();
  confirmCtrl.dispose();
  if (!ok || !context.mounted) return;

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
              const FxLoading(size: 24),
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

class _ExcluirContaCampos extends StatefulWidget {
  const _ExcluirContaCampos({
    required this.dio,
    required this.senhaCtrl,
    required this.codigoCtrl,
    required this.confirmCtrl,
    required this.onModoChanged,
  });

  final Dio dio;
  final TextEditingController senhaCtrl;
  final TextEditingController codigoCtrl;
  final TextEditingController confirmCtrl;
  final ValueChanged<bool> onModoChanged;

  @override
  State<_ExcluirContaCampos> createState() => _ExcluirContaCamposState();
}

class _ExcluirContaCamposState extends State<_ExcluirContaCampos> {
  bool _usarCodigo = false;
  bool _enviando = false;

  Future<void> _pedirCodigo() async {
    if (_enviando) return;
    final l10n = S.of(context);
    setState(() => _enviando = true);
    try {
      final resp = await widget.dio.post<Map<String, dynamic>>(
        excluirContaCodigoPath,
        options: Options(extra: {'fxNoRetry': true, 'fxNoInvalidate': true}),
      );
      final email = resp.data?['emailMascarado']?.toString() ?? '';
      if (!mounted) return;
      setState(() => _usarCodigo = true);
      widget.onModoChanged(true);
      FeedbackHelper.showSuccess(context, l10n.excluirContaCodigoEnviado(email));
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _usarSenha() {
    setState(() => _usarCodigo = false);
    widget.onModoChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usarCodigo)
          TextField(
            controller: widget.codigoCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            decoration: FxInputDeco.build(context, l10n.excluirContaCodigoLabel),
          )
        else
          TextField(
            controller: widget.senhaCtrl,
            obscureText: true,
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            decoration: FxInputDeco.build(context, l10n.excluirContaSenhaLabel),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _enviando ? null : _pedirCodigo,
            child: _enviando
                ? const FxLoading(size: 18, strokeWidth: 2)
                : Text(
                    _usarCodigo
                        ? l10n.excluirContaReenviarCodigo
                        : l10n.excluirContaPedirCodigo,
                  ),
          ),
        ),
        if (_usarCodigo)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _usarSenha,
              child: Text(l10n.excluirContaUsarSenha),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.confirmCtrl,
          onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
          decoration: FxInputDeco.build(context, l10n.excluirContaConfirmLabel),
        ),
      ],
    );
  }
}
