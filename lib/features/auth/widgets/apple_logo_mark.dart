import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Logo da Apple do pacote `sign_in_with_apple` (o desenho do botão oficial),
/// na proporção 25:31. A revisão da App Store recusa o botão "Continuar com
/// Apple" com logo de biblioteca de ícones (diretriz 4, 1.2.6 em 21/11/2026).
class AppleLogoMark extends StatelessWidget {
  const AppleLogoMark({super.key, this.altura = 20, this.cor = Colors.white});

  final double altura;
  final Color cor;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: altura * (25 / 31),
      height: altura,
      child: CustomPaint(painter: AppleLogoPainter(color: cor)),
    ),
  );
}
