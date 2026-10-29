import 'package:flutter/material.dart';

import '../../../core/theme/hero_teal.dart';

/// Ação em texto do login, sem pílula: o login é a única tela em que o
/// produto aceita link de texto (acabamento fino). Área de toque de 48 dp,
/// cor de marca clara e sublinhado leve para parecer clicável.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 14,
    this.cor,
  });

  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final cor = this.cor ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                style: TextStyle(
                  color: _legivel(cor),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: _legivel(cor).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A cor de marca pode ser escura sobre o fundo escuro: clareia até ler.
  static Color _legivel(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness(hsl.lightness < 0.62 ? 0.68 : hsl.lightness).toColor();
  }
}

/// Frase curta + [AuthTextLink] na mesma linha ("Não tem conta? Criar conta").
class AuthFraseComLink extends StatelessWidget {
  const AuthFraseComLink({
    super.key,
    required this.frase,
    required this.acao,
    required this.onTap,
  });

  final String frase;
  final String acao;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          frase.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(color: heroTealSurface(0.82), fontSize: 14),
        ),
        AuthTextLink(label: acao, onTap: onTap),
      ],
    );
  }
}
