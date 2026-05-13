import 'package:flutter/material.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

/// Google-branded sign-in button following the official identity guidelines:
/// - white surface (or dark variant)
/// - 4-color G mark drawn via CustomPainter (no extra deps)
/// - Roboto-style label, 1dp border, soft elevation
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.label = 'Entrar com Google',
    this.dark = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  /// When true, uses the dark theme variant from Google brand spec
  /// (#131314 background, white text). Default false = white surface.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final bg = dark ? const Color(0xFF131314) : Colors.white;
    final fg = dark ? Colors.white : const Color(0xFF1F1F1F);
    final border = dark ? const Color(0xFF8E918F) : const Color(0xFFDADCE0);

    return Semantics(
      label: label,
      button: true,
      enabled: !disabled,
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: const Color(0x14000000),
            highlightColor: const Color(0x0A000000),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        isLoading
                            ? FxLoading(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(fg),
                            )
                            : CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
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

/// Paints the Google G mark using SVG path data normalized to a 24x24 box.
/// Source: official Google Identity guidelines (4-color logo).
class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue (right + horizontal bar)
    paint.color = _blue;
    final blue =
        Path()
          ..moveTo(23.49 * s, 12.275 * s)
          ..cubicTo(
            23.49 * s,
            11.49 * s,
            23.42 * s,
            10.73 * s,
            23.29 * s,
            10.0 * s,
          )
          ..lineTo(12 * s, 10.0 * s)
          ..lineTo(12 * s, 14.51 * s)
          ..lineTo(18.47 * s, 14.51 * s)
          ..cubicTo(
            18.18 * s,
            15.99 * s,
            17.34 * s,
            17.245 * s,
            16.085 * s,
            18.085 * s,
          )
          ..lineTo(16.085 * s, 21.025 * s)
          ..lineTo(19.93 * s, 21.025 * s)
          ..cubicTo(
            22.18 * s,
            18.955 * s,
            23.49 * s,
            15.92 * s,
            23.49 * s,
            12.275 * s,
          )
          ..close();
    canvas.drawPath(blue, paint);

    // Green (bottom)
    paint.color = _green;
    final green =
        Path()
          ..moveTo(12 * s, 24 * s)
          ..cubicTo(
            15.24 * s,
            24 * s,
            17.95 * s,
            22.92 * s,
            19.93 * s,
            21.025 * s,
          )
          ..lineTo(16.085 * s, 18.085 * s)
          ..cubicTo(
            15.005 * s,
            18.815 * s,
            13.62 * s,
            19.245 * s,
            12 * s,
            19.245 * s,
          )
          ..cubicTo(
            8.875 * s,
            19.245 * s,
            6.225 * s,
            17.135 * s,
            5.28 * s,
            14.3 * s,
          )
          ..lineTo(1.305 * s, 14.3 * s)
          ..lineTo(1.305 * s, 17.335 * s)
          ..cubicTo(3.275 * s, 21.245 * s, 7.32 * s, 24 * s, 12 * s, 24 * s)
          ..close();
    canvas.drawPath(green, paint);

    // Yellow (left)
    paint.color = _yellow;
    final yellow =
        Path()
          ..moveTo(5.28 * s, 14.3 * s)
          ..cubicTo(
            5.04 * s,
            13.57 * s,
            4.905 * s,
            12.795 * s,
            4.905 * s,
            12 * s,
          )
          ..cubicTo(
            4.905 * s,
            11.205 * s,
            5.04 * s,
            10.43 * s,
            5.28 * s,
            9.7 * s,
          )
          ..lineTo(5.28 * s, 6.665 * s)
          ..lineTo(1.305 * s, 6.665 * s)
          ..cubicTo(0.49 * s, 8.29 * s, 0 * s, 10.135 * s, 0 * s, 12 * s)
          ..cubicTo(
            0 * s,
            13.865 * s,
            0.49 * s,
            15.71 * s,
            1.305 * s,
            17.335 * s,
          )
          ..lineTo(5.28 * s, 14.3 * s)
          ..close();
    canvas.drawPath(yellow, paint);

    // Red (top)
    paint.color = _red;
    final red =
        Path()
          ..moveTo(12 * s, 4.755 * s)
          ..cubicTo(
            13.77 * s,
            4.755 * s,
            15.355 * s,
            5.365 * s,
            16.605 * s,
            6.555 * s,
          )
          ..lineTo(20.025 * s, 3.135 * s)
          ..cubicTo(17.95 * s, 1.19 * s, 15.24 * s, 0 * s, 12 * s, 0 * s)
          ..cubicTo(7.32 * s, 0 * s, 3.275 * s, 2.755 * s, 1.305 * s, 6.665 * s)
          ..lineTo(5.28 * s, 9.7 * s)
          ..cubicTo(
            6.225 * s,
            6.865 * s,
            8.875 * s,
            4.755 * s,
            12 * s,
            4.755 * s,
          )
          ..close();
    canvas.drawPath(red, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
