import 'package:flutter/material.dart';

import '../../../core/widgets/fx_loading.dart';

/// Botão de entrada social fino (pílula de contorno), igual para Apple e
/// Google: nenhum pesa mais que o outro nem que o "Entrar".
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    required this.leading,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;
  final bool loading;

  static const double altura = 52;

  @override
  Widget build(BuildContext context) {
    final desabilitado = onPressed == null || loading;
    return Semantics(
      label: label,
      button: true,
      enabled: !desabilitado,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null && !loading ? 0.6 : 1,
        child: Material(
          color: Colors.white.withValues(alpha: 0.05),
          shape: StadiumBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: desabilitado ? null : onPressed,
            child: SizedBox(
              height: altura,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        loading
                            ? const FxLoading(
                              size: 18,
                              strokeWidth: 2.2,
                              color: Colors.white,
                            )
                            : leading,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
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
