import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class FxLogo extends StatelessWidget {
  final double size;

  const FxLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/focuxlogopremium.png',
      width: size,
      height: size,
    );
  }
}
