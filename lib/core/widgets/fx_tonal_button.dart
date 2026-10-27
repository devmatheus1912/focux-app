import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import 'fx_action_chip.dart';
import 'fx_loading.dart';

/// Ação secundária: fundo tonal da marca, ícone opcional e área de toque de 44.
/// Mesma paleta do [FxActionChip]; esta peça cresce com o texto e aceita ícone
/// e carregamento. O botão principal da tela continua sendo o preenchido.
class FxTonalButton extends StatelessWidget {
  const FxTonalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.loading = false,
    this.expanded = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// 36 de altura visível (a área de toque segue com 44) para linhas densas.
  final bool compact;
  final bool loading;

  /// Ocupa a largura toda; senão, só o que o texto pede.
  final bool expanded;

  /// Leitura mais específica que o texto ('Adicionar em Aquecimento').
  final String? semanticLabel;

  static const double alturaToque = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final fg = FxActionChip.tonalForeground(accent, isDark: isDark);
    final bg = FxActionChip.tonalBackground(accent, isDark: isDark);
    final enabled = onPressed != null && !loading;
    final altura = compact ? 36.0 : alturaToque;

    final conteudo = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          FxLoading(size: 16, strokeWidth: 2, color: fg)
        else if (icon != null)
          Icon(icon, size: 18, color: fg),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.bodyMuted(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: alturaToque),
        child: Align(
          widthFactor: expanded ? null : 1,
          alignment: Alignment.center,
          child: Material(
            color: enabled ? bg : bg.withValues(alpha: 0.5),
            shape: StadiumBorder(
              side: BorderSide(color: accent.withValues(alpha: isDark ? 0.40 : 0.28)),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap:
                  enabled
                      ? () {
                        HapticFeedback.selectionClick();
                        onPressed!();
                      }
                      : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: altura),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? TokensStrip.s3 : TokensStrip.s4,
                  ),
                  child: conteudo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
