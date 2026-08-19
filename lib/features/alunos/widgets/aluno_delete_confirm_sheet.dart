import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../data/aluno_repository.dart';

class AlunoDeleteConfirmSheet extends StatefulWidget {
  const AlunoDeleteConfirmSheet({
    super.key,
    required this.aluno,
    required this.confirmToken,
  });

  final Aluno aluno;
  final String confirmToken;

  @override
  State<AlunoDeleteConfirmSheet> createState() =>
      _AlunoDeleteConfirmSheetState();
}

class _AlunoDeleteConfirmSheetState extends State<AlunoDeleteConfirmSheet> {
  late final TextEditingController _controller;
  var _inputMatches = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final displayName = fxTitleCaseName(widget.aluno.nome);

    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Excluir aluno?',
            subtitle: '$displayName será removido permanentemente.',
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: EagleTokens.bad,
              size: 18,
            ),
          ),
          SizedBox(height: TokensStrip.s3),
          Text(
            'Treinos, check-ins e histórico vinculados também serão apagados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            'Esta ação não pode ser desfeita.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EagleTokens.bad.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Digite "${widget.confirmToken}" para confirmar:',
              style: TextStyle(
                color: mute,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onChanged:
                (value) => setState(
                  () =>
                      _inputMatches =
                          value.trim().toLowerCase() == widget.confirmToken,
                ),
            onSubmitted: (_) {
              if (_inputMatches) {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop(true);
              }
            },
            decoration: InputDecoration(
              hintText: widget.confirmToken,
              isDense: true,
              filled: true,
              fillColor: EagleTokens.bad.withValues(
                alpha: isDark ? 0.08 : 0.05,
              ),
              enabledBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: line),
              ),
              focusedBorder: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: EagleTokens.bad.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _inputMatches
                      ? () {
                        HapticFeedback.heavyImpact();
                        Navigator.of(context).pop(true);
                      }
                      : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('Excluir $displayName'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EagleTokens.bad,
                foregroundColor: Colors.white,
                disabledBackgroundColor: EagleTokens.bad.withValues(
                  alpha: 0.35,
                ),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: mute, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
