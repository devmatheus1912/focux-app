import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _gridCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the logo ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Fade-in for text elements
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeCtrl.forward();
    });

    // Grid subtle motion
    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUnauthenticated(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final vistoPrimeiroAcesso = prefs.getBool('onboarding_done') ?? false;
    if (!vistoPrimeiroAcesso) {
      await prefs.setBool('onboarding_done', true);
      if (context.mounted) context.go('/onboarding');
    } else {
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      if (next == AuthStatus.authenticated) {
        final role = ref.read(userRoleProvider);
        if (role == UserRole.aluno) {
          context.go('/dashboard/aluno');
        } else {
          context.go('/dashboard/personal');
        }
      } else if (next == AuthStatus.unauthenticated) {
        _handleUnauthenticated(context);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Deep gradient background
          Container(
            decoration: BoxDecoration(
              gradient: EagleTokens.heroGradient(dark: true),
            ),
          ),

          // Animated grid overlay
          AnimatedBuilder(
            animation: _gridCtrl,
            builder: (context, child) {
              return CustomPaint(
                painter: _GridPainter(
                  progress: _gridCtrl.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Anel pulsante + ícone F grande
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Anel externo pulsante
                        Container(
                          width: 180 * _pulseAnim.value,
                          height: 180 * _pulseAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: EagleTokens.brand.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: EagleTokens.brand.withValues(alpha: 0.12 * _pulseAnim.value),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        // Ícone F grande
                        FxLogo(iconSize: 100, showLabel: false),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Nome: "Focux Personal" grande com fade
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Focux',
                              style: TextStyle(
                                color: EagleTokens.darkInk,
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: ' Personal',
                              style: TextStyle(
                                color: EagleTokens.darkInkMute,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Performance Intelligence',
                        style: TextStyle(
                          color: EagleTokens.darkInkMute,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EagleTokens.brand.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom brand
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'by Focux Labs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EagleTokens.inkMute,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EagleTokens.darkInk.withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    final offset = progress * spacing;

    // Vertical lines
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Glow dots at intersections (sparse)
    final dotPaint = Paint()
      ..color = EagleTokens.brand.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (double x = offset; x < size.width; x += spacing * 3) {
      for (double y = offset; y < size.height; y += spacing * 3) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
