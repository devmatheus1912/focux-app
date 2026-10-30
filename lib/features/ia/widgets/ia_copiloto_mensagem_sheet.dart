import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';

/// Mensagem sugerida, editável, antes de ir para o chat do aluno.
Future<String?> showIaCopilotoMensagemSheet(
  BuildContext context, {
  required String mensagem,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final s = S.of(context);
  return showFxHomeSheet<String>(
    context,
    isScrollControlled: true,
    builder:
        (ctx) => FxHomeSheetScaffold(
          isDark: isDark,
          leading: Icon(
            Icons.chat_bubble_outline_rounded,
            color: Theme.of(ctx).colorScheme.primary,
            size: 22,
          ),
          title: s.copilotoMensagemTitulo,
          subtitle: s.copilotoMensagemSubtitulo,
          child: _Corpo(mensagem: mensagem),
        ),
  );
}

class _Corpo extends StatefulWidget {
  const _Corpo({required this.mensagem});

  final String mensagem;

  @override
  State<_Corpo> createState() => _CorpoState();
}

class _CorpoState extends State<_Corpo> {
  late final _ctrl = TextEditingController(text: widget.mensagem);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final texto = _ctrl.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            maxLines: 5,
            minLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: FxInputDeco.build(context, s.copilotoMensagemCampo),
          ),
          const SizedBox(height: TokensStrip.s3),
          FxLiquidPrimaryButton(
            label: s.copilotoMensagemEnviar,
            onPressed:
                texto.isEmpty ? null : () => Navigator.of(context).pop(texto),
          ),
        ],
      ),
    );
  }
}
