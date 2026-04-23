import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Logo completo do Focux Personal — 100% Flutter, sem imagem.
///
/// Renderiza um ícone "F" com gradiente azul glassmorphism + texto "ocux Personal".
/// Parâmetros:
/// - [iconSize]   — tamanho do bloco do ícone F (padrão: 56)
/// - [showLabel]  — exibe o texto "ocux Personal" (padrão: true)
/// - [horizontal] — ícone e texto lado a lado (padrão: true)
/// - [light]      — texto branco para fundos escuros (padrão: true)
class FxLogo extends StatelessWidget {
  final double iconSize;
  final bool showLabel;
  final bool horizontal;
  final bool light;

  const FxLogo({
    super.key,
    this.iconSize = 56,
    this.showLabel = true,
    this.horizontal = true,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _FxIcon(size: iconSize);

    if (!showLabel) return icon;

    final nameColor = light ? Colors.white : EagleTokens.ink;
    final subColor = light
        ? Colors.white.withValues(alpha: 0.55)
        : EagleTokens.inkMute;

    final nameSize = (iconSize * 0.52).clamp(14.0, 36.0);
    final subSize = (iconSize * 0.28).clamp(9.0, 18.0);

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'ocux',
                style: TextStyle(
                  color: nameColor,
                  fontSize: nameSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'Personal',
          style: TextStyle(
            color: subColor,
            fontSize: subSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            height: 1.1,
          ),
        ),
      ],
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          SizedBox(width: iconSize * 0.14),
          label,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: iconSize * 0.16),
        label,
      ],
    );
  }
}

/// Ícone "F" glassmorphism puro em Flutter.
class _FxIcon extends StatelessWidget {
  final double size;
  const _FxIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5B7FFF), // azul claro highlight
            Color(0xFF3B5FE2), // Electric Royal
            Color(0xFF1A3ABF), // azul médio
            Color(0xFF0D1B5C), // BrandDeep
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B5FE2).withValues(alpha: 0.55),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.1),
            spreadRadius: -size * 0.05,
          ),
          BoxShadow(
            color: const Color(0xFF5B7FFF).withValues(alpha: 0.15),
            blurRadius: size * 0.2,
            offset: Offset(-size * 0.05, -size * 0.05),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Reflexo de vidro no canto superior
          Positioned(
            top: size * 0.06,
            left: size * 0.1,
            right: size * 0.15,
            child: Container(
              height: size * 0.28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius * 0.8),
                  topRight: Radius.circular(radius * 0.8),
                  bottomLeft: Radius.circular(radius * 0.2),
                  bottomRight: Radius.circular(radius * 0.2),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Letra F centralizada
          Center(
            child: Text(
              'F',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.62,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -1,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: size * 0.1,
                    offset: Offset(0, size * 0.04),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Versão apenas do ícone F — para AppBars, avatares, etc.
class FxLogoIcon extends StatelessWidget {
  final double size;
  const FxLogoIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => _FxIcon(size: size);
}
