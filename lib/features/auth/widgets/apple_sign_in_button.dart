import 'package:flutter/material.dart';

import '../../../core/widgets/fx_loading.dart';

/// Botão “Continuar com Apple”. As telas de auth são sempre escuras, então
/// usa a variante branca (padrão da Apple para fundo escuro).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.label = 'Continuar com Apple',
    this.compacto = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  /// Lado a lado com outro botão: altura 56, rótulo em até 2 linhas.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    const bg = Color(0xFFFFFFFF);
    const fg = Color(0xFF000000);

    return Semantics(
      label: label,
      button: true,
      enabled: !disabled,
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: const Color(0x33000000),
            highlightColor: const Color(0x1A000000),
            child: Container(
              height: compacto ? 56 : 52,
              padding: EdgeInsets.symmetric(horizontal: compacto ? 10 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        isLoading
                            ? const FxLoading(
                              size: 18,
                              strokeWidth: 2.2,
                              color: fg,
                            )
                            : const Icon(Icons.apple, size: 22, color: fg),
                  ),
                  SizedBox(width: compacto ? 8 : 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: compacto ? 2 : 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: compacto ? 13.5 : 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        height: compacto ? 1.2 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
