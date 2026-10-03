import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../data/moderacao_repository.dart';

/// Abre o fluxo de denúncia e envia para a moderação Focux.
/// Retorna `true` se a denúncia foi enviada.
Future<bool> showDenunciarSheet(
  BuildContext context, {
  required ModeracaoRepository repo,
  required DenunciaTipo tipo,
  String? alvoId,
  String? conteudo,
}) async {
  final enviada = await showFxHomeSheet<bool>(
    context,
    builder: (_) => _DenunciarSheet(
      repo: repo,
      tipo: tipo,
      alvoId: alvoId,
      conteudo: conteudo,
    ),
  );
  if (enviada == true && context.mounted) {
    FeedbackHelper.showSuccess(context, S.of(context).moderacaoEnviada);
  }
  return enviada == true;
}

String denunciaMotivoLabel(S l10n, DenunciaMotivo m) => switch (m) {
  DenunciaMotivo.spam => l10n.moderacaoMotivoSpam,
  DenunciaMotivo.ofensivo => l10n.moderacaoMotivoOfensivo,
  DenunciaMotivo.assedio => l10n.moderacaoMotivoAssedio,
  DenunciaMotivo.inadequado => l10n.moderacaoMotivoInadequado,
  DenunciaMotivo.outro => l10n.moderacaoMotivoOutro,
};

class _DenunciarSheet extends StatefulWidget {
  const _DenunciarSheet({
    required this.repo,
    required this.tipo,
    this.alvoId,
    this.conteudo,
  });

  final ModeracaoRepository repo;
  final DenunciaTipo tipo;
  final String? alvoId;
  final String? conteudo;

  @override
  State<_DenunciarSheet> createState() => _DenunciarSheetState();
}

class _DenunciarSheetState extends State<_DenunciarSheet> {
  final _detalhe = TextEditingController();
  DenunciaMotivo? _motivo;
  bool _enviando = false;

  @override
  void dispose() {
    _detalhe.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final motivo = _motivo;
    if (motivo == null || _enviando) return;
    setState(() => _enviando = true);
    try {
      await widget.repo.denunciar(
        tipo: widget.tipo,
        motivo: motivo,
        alvoId: widget.alvoId,
        detalhe: _detalhe.text,
        conteudo: widget.conteudo,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final cardBg = dark ? EagleTokens.darkCard : TokensStrip.cardBg;

    return FxHomeSheetScaffold(
      isDark: dark,
      leading: Icon(Icons.flag_outlined, color: brand, size: 18),
      title: l10n.moderacaoTitulo,
      subtitle: l10n.moderacaoSubtitulo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<DenunciaMotivo>(
            groupValue: _motivo,
            onChanged: (m) => setState(() => _motivo = m),
            child: Column(
              children: [
                for (final m in DenunciaMotivo.values)
                  RadioListTile<DenunciaMotivo>(
                    value: m,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: brand,
                    title: Text(
                      denunciaMotivoLabel(l10n, m),
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          TextField(
            controller: _detalhe,
            minLines: 2,
            maxLines: 4,
            inputFormatters: [
              LengthLimitingTextInputFormatter(ModeracaoRepository.detalheMax),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: cardBg,
              hintText: l10n.moderacaoDetalheHint,
              hintStyle: TextStyle(color: mute),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: line),
              ),
              focusedBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: brand, width: 1.2),
              ),
            ),
            style: TextStyle(color: ink, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: TokensStrip.s4),
          FxLiquidPrimaryButton(
            label: l10n.moderacaoEnviar,
            onPressed: _motivo == null || _enviando ? null : _enviar,
          ),
        ],
      ),
    );
  }
}
