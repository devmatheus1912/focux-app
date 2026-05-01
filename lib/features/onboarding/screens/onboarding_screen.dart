import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — FxIntroSlides (Onboarding)
// Aligned exactly with screen-auth.jsx V3 handoff
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _current = 0;

  static const _pages = [
    _OBData(
      icon: Icons.fitness_center_rounded,
      title: 'Seus alunos,\nsua gestão.',
      subtitle:
          'Cadastre alunos, monte treinos e acompanhe a evolução de cada um em tempo real.',
      accent: EagleTokens.brandAccent,
    ),
    _OBData(
      icon: Icons.auto_awesome_rounded,
      title: 'IA que\nentende treino.',
      subtitle:
          'Gere treinos e dietas personalizados em segundos. A IA aprende com o histórico de cada aluno.',
      accent: Color(0xFFA0CCFF),
    ),
    _OBData(
      icon: Icons.attach_money_rounded,
      title: 'Financeiro\nsem complicação.',
      subtitle:
          'Cobranças, inadimplências e relatórios automatizados. Você foca no que importa: resultados.',
      accent: Color(0xFFB8D9FF),
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_current < _pages.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: EagleTokens.heroGradient(dark: true),
              ),
            ),

            // Grid pattern
            CustomPaint(painter: _AuthGridPainter(), size: Size.infinite),

            // Ambient glow
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Skip Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: EagleTokens.darkInk.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          child: const Text(
                            'Pular',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pages
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (_, i) => _OBPageWidget(data: _pages[i]),
                    ),
                  ),

                  // Dots
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => GestureDetector(
                          onTap:
                              () => _page.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                              ),
                          child: _SlideDot(active: _current == i),
                        ),
                      ),
                    ),
                  ),

                  // CTA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [primary, EagleTokens.brandDeep],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _next,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: primary.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _current < 2
                                        ? 'Próximo →'
                                        : 'Começar agora',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (_current == 2) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                              children: [
                                const TextSpan(text: 'Já tenho uma conta · '),
                                TextSpan(
                                  text: 'Entrar',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════

class _OBData {
  final IconData icon;
  final String title, subtitle;
  final Color accent;
  const _OBData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

class _SlideDot extends StatelessWidget {
  final bool active;

  const _SlideDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: active ? 28 : 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _OBPageWidget extends StatelessWidget {
  final _OBData data;
  const _OBPageWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Illustration
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 32, top: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withValues(alpha: 0.32),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner radial glow behind icon
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            data.accent.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                    Icon(data.icon, color: data.accent, size: 52),
                  ],
                ),
              ),
            ),
          ),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.85,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          SizedBox(
            width: 300,
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID
// ═══════════════════════════════════════════════════════════════════════════

class _AuthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
