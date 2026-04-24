import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/fx_logo.dart';
import '../../../core/theme/design_tokens.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── L1: Deep gradient (same as register) ────────────────
            Container(
              decoration: BoxDecoration(
                gradient: EagleTokens.heroGradient(dark: isDark),
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
                      EagleTokens.brand.withValues(alpha: 0.06),
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
                                EagleTokens.darkInk.withValues(alpha: 0.45),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Text('Pular',
                              style: TextStyle(
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
                          _OBPageWidget(data: _pages[i], isDark: isDark),
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
                                    ? EagleTokens.brand
                                    : EagleTokens.darkInk.withValues(alpha: 0.10),
                                boxShadow: _current == i
                                    ? [BoxShadow(
                                        color: EagleTokens.brand
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
                              gradient: LinearGradient(
                                colors: [EagleTokens.brand, EagleTokens.brandInk],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: EagleTokens.brand.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _current == _pages.length - 1
                                  ? Text('Começar',
                                      style: TextStyle(
                                        color: EagleTokens.darkInk,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ))
                                  : Icon(
                                      Icons.arrow_forward_rounded,
                                      color: EagleTokens.darkInk,
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
  final bool isDark;
  const _OBPageWidget({required this.data, required this.isDark});

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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [EagleTokens.darkCard, EagleTokens.darkCardHi],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: EagleTokens.brandAccent.withValues(alpha: 0.22),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EagleTokens.brandAccent.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: EagleTokens.brandAccent.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(data.icon,
                    color: EagleTokens.brandSoft, size: 42),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tag badge — glass + glow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: EagleTokens.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: EagleTokens.brand.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Text(data.tag,
                style: TextStyle(
                  color: EagleTokens.brandAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                )),
          ),

          const SizedBox(height: 20),

          // Title with glow
          Text(
            data.title,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.brandSoft,
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
            style: TextStyle(
              color: isDark
                  ? EagleTokens.darkInkMute
                  : EagleTokens.darkInk.withValues(alpha: 0.55),
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
      ..color = EagleTokens.darkInk.withValues(alpha: 0.008)
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
