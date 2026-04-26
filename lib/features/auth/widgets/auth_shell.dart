import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.85),
              radius: 1.35,
              colors:
                  dark
                      ? const [
                        Color(0xFF1A3A7A),
                        Color(0xFF060C1E),
                        Color(0xFF020818),
                      ]
                      : const [
                        Color(0xFF1836A0),
                        Color(0xFF0D1B5C),
                        Color(0xFF070F33),
                      ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        CustomPaint(painter: const _AuthGridPainter(), size: Size.infinite),
        Positioned(
          top: -80,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.fromRGBO(124, 192, 255, 0.18),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({super.key, this.size = 110});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.26;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color(0xFF1A3A7A), Color(0xFF070E2A)],
          stops: [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B5FE2).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color.fromRGBO(124, 192, 255, 0.12),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ShaderMask(
        shaderCallback: (Rect bounds) => const RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color(0xFF1A3A7A), Color(0xFF070E2A)],
          stops: [0.0, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.screen,
        child: OverflowBox(
          maxWidth: size * 1.3,
          maxHeight: size * 1.3,
          child: Image.asset(
            'assets/images/logo_icon.png',
            width: size * 1.3,
            height: size * 1.3,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
      ),
    );
  }
}

class AuthWordmark extends StatelessWidget {
  const AuthWordmark({
    super.key,
    this.center = true,
    this.titleSize = 42,
    this.subtitleSize = 15,
    this.taglineSize = 13,
  });

  final bool center;
  final double titleSize;
  final double subtitleSize;
  final double taglineSize;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.left;
    final crossAxis =
        center ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          'FOCUX',
          textAlign: align,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PERSONAL',
          textAlign: align,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: subtitleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: subtitleSize * 0.28,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Treine com dados. Evolua com inteligência.',
          textAlign: align,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: taglineSize,
            fontStyle: FontStyle.italic,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon:
                icon == null
                    ? null
                    : Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 18,
                    ),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: EagleTokens.brandAccent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B)),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFFB6B6),
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Design spec: LinearGradient 135° brand→brandInk + shadow 8px -8px brand 60%
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EagleTokens.brand,
              isLoading
                  ? EagleTokens.brand.withValues(alpha: 0.45)
                  : EagleTokens.brandInk,
            ],
          ),
          boxShadow: [
            if (!isLoading)
              BoxShadow(
                color: EagleTokens.brand.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    required this.onTap,
    this.showLabel = false,
  });

  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );

    if (!showLabel) {
      return button;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 10),
        Text(
          'Voltar',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AuthPlanCard extends StatelessWidget {
  const AuthPlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient:
              selected
                  ? const LinearGradient(
                    colors: [EagleTokens.brand, EagleTokens.brandInk],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.07),
          border:
              selected
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow:
              selected
                  ? const [
                    BoxShadow(
                      color: Color.fromRGBO(59, 95, 226, 0.4),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.48,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthGridPainter extends CustomPainter {
  const _AuthGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
