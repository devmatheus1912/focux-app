import 'package:flutter/material.dart';

import '../../../core/widgets/fx_loading.dart';

/// Botão “Continuar com Apple” (fundo preto, ícone, label claro).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.label = 'Continuar com Apple',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    const bg = Color(0xFF000000);
    const fg = Color(0xFFFFFFFF);

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
            splashColor: const Color(0x33FFFFFF),
            highlightColor: const Color(0x1AFFFFFF),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
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
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
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
