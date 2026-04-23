import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/fx_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — Glow Effect Premium Onboarding
// Same visual language as login: dramatic glow, glass, breathing animations
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
      title: 'Gestão inteligente\nde alunos.',
      subtitle:
          'Cadastre, acompanhe a evolução e reduza o churn com dados em tempo real.',
      tag: 'GESTÃO',
    ),
    _OBData(
      icon: Icons.auto_awesome_rounded,
      title: 'IA que trabalha\npor você.',
      subtitle:
          'Gere treinos, dietas e progressões de carga automaticamente com inteligência artificial.',
      tag: 'INTELIGÊNCIA',
    ),
    _OBData(
      icon: Icons.insights_rounded,
      title: 'Resultados\nmensuráveis.',
      subtitle:
          'Monitore check-ins, aderência, evolução física e engajamento de cada aluno.',
      tag: 'ANALYTICS',
    ),
    _OBData(
      icon: Icons.rocket_launch_rounded,
      title: 'Seu negócio.\nSem limites.',
      subtitle:
          'Controle financeiro, agenda, planos e automações — tudo em um só lugar.',
      tag: 'ESCALA',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_current < _pages.length - 1) {
      _page.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── L1: Deep gradient (same as register) ────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF040B1A),
                    Color(0xFF0F172A),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // ── L2: Radial accent ───────────────────────────────────
            Positioned(
              top: -h * 0.12,
              left: 0,
              right: 0,
              child: Container(
                height: h * 0.50,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.65,
                    colors: [
                      const Color(0xFF2F6BFF).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── L3: Grid ────────────────────────────────────────────
            CustomPaint(painter: _PremiumGrid(), size: Size.infinite),

            // ── L5: Content ─────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Header: Logo + Skip
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const FxLogo(
                            iconSize: 42, showLabel: true, light: true),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.45),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Text('Pular',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3)),
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
                      itemBuilder: (_, i) =>
                          _OBPageWidget(data: _pages[i]),
                    ),
                  ),

                  // Bottom: indicators + glow action button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 20),
                    child: Row(
                      children: [
                        // Page dots
                        Row(
                          children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.only(right: 6),
                              width: _current == i ? 28 : 8,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: _current == i
                                    ? const Color(0xFF3B82F6)
                                    : Colors.white.withValues(alpha: 0.10),
                                boxShadow: _current == i
                                    ? [BoxShadow(
                                        color: const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.50),
                                        blurRadius: 8)]
                                    : [],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Action button
                        GestureDetector(
                          onTap: _next,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _current == _pages.length - 1 ? 160 : 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F6BFF).withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _current == _pages.length - 1
                                  ? Text('Começar',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ))
                                  : const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
  final String title, subtitle, tag;
  const _OBData(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.tag});
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon card — glass with glow
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F6BFF).withValues(alpha: 0.15),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(data.icon,
                    color: const Color(0xFF7BA3FF), size: 42),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tag badge — glass + glow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2F6BFF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF2F6BFF).withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Text(data.tag,
                style: GoogleFonts.inter(
                  color: const Color(0xFF7BA3FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                )),
          ),

          const SizedBox(height: 20),

          // Title with glow
          Text(
            data.title,
            style: GoogleFonts.inter(
              color: const Color(0xFFF0F4FF),
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.08,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 14),

          // Subtitle
          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.55,
              letterSpacing: 0.1,
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

class _PremiumGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.008)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
