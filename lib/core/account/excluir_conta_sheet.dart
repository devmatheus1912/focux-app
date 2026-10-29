import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../legal/focux_legal.dart';
import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import '../utils/friendly_error.dart';
import '../widgets/feedback_helper.dart';
import '../widgets/fx_home_sheet.dart';
import '../widgets/fx_input_deco.dart';
import '../widgets/fx_keyboard_dismiss_scope.dart';
import '../widgets/fx_sheet_frame.dart';
import '../widgets/fx_tonal_button.dart';
import 'excluir_conta_flow.dart';

/// Quem está excluindo: muda só as linhas de "O que acontece".
enum ExcluirContaPapel { personal, aluno }

/// O que o titular preencheu. Só sai da folha quando tudo está válido.
class ExcluirContaCredencial {
  const ExcluirContaCredencial({
    required this.senha,
    required this.codigo,
    required this.confirmacao,
    required this.usarCodigo,
  });

  final String senha;
  final String codigo;
  final String confirmacao;
  final bool usarCodigo;
}

/// Linhas de "O que acontece", na ordem em que aparecem. A última é sempre o
/// aviso de que não dá para desfazer.
List<String> excluirContaConsequencias(
  S l10n,
  ExcluirContaPapel papel, {
  bool avisoAssinatura = false,
}) {
  return switch (papel) {
    ExcluirContaPapel.aluno => [
      l10n.excluirContaAcAluno1,
      l10n.excluirContaAcAluno2,
      l10n.excluirContaAcAluno3,
      l10n.excluirContaAcComum,
    ],
    ExcluirContaPapel.personal => [
      l10n.excluirContaAcPersonal1,
      l10n.excluirContaAcPersonal2,
      l10n.excluirContaAcPersonal3,
      l10n.excluirContaAcPersonal4,
      if (avisoAssinatura) l10n.excluirContaAvisoAssinatura,
      l10n.excluirContaAcComum,
    ],
  };
}

/// Credencial e confirmação válidas: habilita o botão vermelho.
bool excluirContaPodeExcluir({
  required String senha,
  required String codigo,
  required String confirmacao,
  required bool usarCodigo,
}) {
  if (confirmacao.trim() != 'EXCLUIR') return false;
  return usarCodigo ? codigo.trim().length == 6 : senha.isNotEmpty;
}

/// Folha de exclusão de conta em passos: entender, provar quem é, confirmar.
Future<ExcluirContaCredencial?> showExcluirContaSheet(
  BuildContext context, {
  required Dio dio,
  required ExcluirContaPapel papel,
  bool avisoAssinatura = false,
}) {
  return showFxHomeSheet<ExcluirContaCredencial>(
    context,
    builder:
        (_) => _ExcluirContaSheet(
          dio: dio,
          papel: papel,
          avisoAssinatura: avisoAssinatura,
        ),
  );
}

class _ExcluirContaSheet extends StatefulWidget {
  const _ExcluirContaSheet({
    required this.dio,
    required this.papel,
    required this.avisoAssinatura,
  });

  final Dio dio;
  final ExcluirContaPapel papel;
  final bool avisoAssinatura;

  @override
  State<_ExcluirContaSheet> createState() => _ExcluirContaSheetState();
}

class _ExcluirContaSheetState extends State<_ExcluirContaSheet> {
  final _senha = TextEditingController();
  final _codigo = TextEditingController();
  final _confirmacao = TextEditingController();
  var _usarCodigo = false;
  var _enviando = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_senha, _codigo, _confirmacao]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _senha.dispose();
    _codigo.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  bool get _valido => excluirContaPodeExcluir(
    senha: _senha.text,
    codigo: _codigo.text,
    confirmacao: _confirmacao.text,
    usarCodigo: _usarCodigo,
  );

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
      FeedbackHelper.showSuccess(context, l10n.excluirContaCodigoEnviado(email));
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _excluir() {
    HapticFeedback.heavyImpact();
    FxHomeSheetChrome.dismissAndPop(
      context,
      ExcluirContaCredencial(
        senha: _senha.text,
        codigo: _codigo.text,
        confirmacao: _confirmacao.text,
        usarCodigo: _usarCodigo,
      ),
    );
  }

  /// Campo preenchido (fundo tonal e borda), para não parecer solto na folha.
  InputDecoration _deco(BuildContext context, String rotulo) {
    final chrome = ShellChrome.of(context);
    final base = FxInputDeco.build(context, rotulo);
    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cor, width: largura),
        );
    return base.copyWith(
      filled: true,
      fillColor: chrome.ink.withValues(alpha: chrome.isDark ? 0.08 : 0.045),
      enabledBorder: borda(chrome.lineStrong),
      focusedBorder: borda(Theme.of(context).colorScheme.primary, 2),
      counterText: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final chrome = ShellChrome.of(context);
    const perigo = EagleTokens.bad;
    final linhas =
        excluirContaConsequencias(l10n, widget.papel)
            .where((l) => l != l10n.excluirContaAcComum)
            .toList();
    final icones = switch (widget.papel) {
      ExcluirContaPapel.aluno => const [
        Icons.shield_outlined,
        Icons.receipt_long_outlined,
        Icons.person_off_outlined,
      ],
      ExcluirContaPapel.personal => const [
        Icons.shield_outlined,
        Icons.group_off_outlined,
        Icons.receipt_long_outlined,
        Icons.credit_card_off_outlined,
      ],
    };

    Widget secao(String titulo) => Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Semantics(
        header: true,
        child: Text(titulo, style: FocuxHubTypography.chip(chrome.mute)),
      ),
    );

    Widget linha(IconData icone, Color cor, String texto, {Color? corTexto}) =>
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 20, color: cor),
            const SizedBox(width: TokensStrip.s3),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  color: corTexto ?? chrome.ink,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: corTexto == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
          ],
        );

    final botaoFundo = Color.alphaBlend(
      perigo.withValues(alpha: chrome.isDark ? 0.3 : 0.2),
      chrome.isDark ? const Color(0xFF1B1F27) : Colors.white,
    );

    return FxSheetFrame(
      title: l10n.excluirContaTitulo,
      subtitle: l10n.excluirContaSubtitulo,
      leading: const Icon(Icons.delete_forever_outlined, color: perigo, size: 20),
      maxHeightFactor: 0.92,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _valido ? _excluir : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: perigo,
                foregroundColor: Colors.white,
                // Desabilitado ainda se lê: texto escuro sobre vermelho claro.
                disabledBackgroundColor: botaoFundo,
                disabledForegroundColor: chrome.isDark
                    ? Colors.white.withValues(alpha: 0.78)
                    : const Color(0xFF5C1A1A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(l10n.excluirContaBotao),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          FxTonalButton(
            label: l10n.excluirContaCancelar,
            expanded: true,
            onPressed: () => FxHomeSheetChrome.dismissAndPop(context),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          secao(l10n.excluirContaSecaoAcontece),
          Container(
            key: const ValueKey('excluir-conta-consequencias'),
            padding: const EdgeInsets.all(TokensStrip.s3),
            decoration: BoxDecoration(
              color: chrome.ink.withValues(alpha: chrome.isDark ? 0.07 : 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < linhas.length; i++) ...[
                  if (i > 0) const SizedBox(height: TokensStrip.s3),
                  linha(
                    icones[i < icones.length ? i : icones.length - 1],
                    chrome.mute,
                    linhas[i],
                  ),
                ],
                const SizedBox(height: TokensStrip.s3),
                linha(
                  Icons.warning_amber_rounded,
                  perigo,
                  l10n.excluirContaAcComum,
                  corTexto: perigo,
                ),
              ],
            ),
          ),
          if (widget.avisoAssinatura) ...[
            const SizedBox(height: TokensStrip.s3),
            Container(
              key: const ValueKey('excluir-conta-alerta-loja'),
              padding: const EdgeInsets.all(TokensStrip.s3),
              decoration: BoxDecoration(
                color: EagleTokens.warn.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EagleTokens.warn.withValues(alpha: 0.5),
                ),
              ),
              child: linha(
                Icons.info_outline_rounded,
                EagleTokens.warn,
                l10n.excluirContaAvisoAssinatura,
              ),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          FxTonalButton(
            label: l10n.excluirContaWebBotao,
            icon: Icons.open_in_new_rounded,
            compact: true,
            onPressed: FocuxLegal.openDeleteAccount,
          ),
          const SizedBox(height: TokensStrip.s4),
          secao(l10n.excluirContaSecaoConfirmar),
          if (_usarCodigo)
            TextField(
              controller: _codigo,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
              decoration: _deco(context, l10n.excluirContaCodigoLabel),
            )
          else
            TextField(
              controller: _senha,
              obscureText: true,
              onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
              decoration: _deco(context, l10n.excluirContaSenhaLabel),
            ),
          const SizedBox(height: TokensStrip.s3),
          if (!_usarCodigo)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s2),
              child: Text(
                l10n.excluirContaSemSenhaDica,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              FxTonalButton(
                label:
                    _usarCodigo
                        ? l10n.excluirContaReenviarCodigo
                        : l10n.excluirContaPedirCodigo,
                icon: Icons.mail_outline_rounded,
                compact: true,
                loading: _enviando,
                onPressed: _enviando ? null : _pedirCodigo,
              ),
              if (_usarCodigo)
                FxTonalButton(
                  label: l10n.excluirContaUsarSenha,
                  icon: Icons.password_rounded,
                  compact: true,
                  onPressed: () => setState(() => _usarCodigo = false),
                ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          secao(l10n.excluirContaSecaoFinalizar),
          TextField(
            controller: _confirmacao,
            textCapitalization: TextCapitalization.characters,
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            decoration: _deco(context, l10n.excluirContaConfirmLabel),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
      ),
    );
  }
}
