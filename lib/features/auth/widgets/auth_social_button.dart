import 'package:flutter/material.dart';

import '../../../core/widgets/fx_loading.dart';

/// Botão fino de contorno (pílula preta), igual para Apple e Google e para as
/// ações secundárias das telas de entrada: nenhum pesa mais que o botão
/// principal. Preto puro (o que a Apple aceita) com contorno cinza.
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    this.leading,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool loading;

  static const double altura = 52;
  static const Color fundo = Color(0xFF000000);
  static const Color borda = Color(0xFF8E918F);

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
          color: fundo,
          shape: const StadiumBorder(side: BorderSide(color: borda)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: desabilitado ? null : onPressed,
            child: SizedBox(
              height: altura,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null || loading) ...[
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
                  ],
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
