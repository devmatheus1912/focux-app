import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _page = PageController();
  int _current = 0;

  late final AnimationController _bgCtrl;

  static const _pages = [
    _OnboardData(
      icon: Icons.fitness_center,
      gradient: [Color(0xFF3B5FE2), Color(0xFF2440B8)],
      title: 'Gestão inteligente\nde alunos.',
      subtitle: 'Cadastre, acompanhe a evolução e reduza o churn com dados em tempo real.',
      tag: 'GESTÃO',
    ),
    _OnboardData(
      icon: Icons.auto_awesome,
      gradient: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      title: 'IA que trabalha\npor você.',
      subtitle: 'Gere treinos, dietas e progressões de carga automaticamente com inteligência artificial.',
      tag: 'INTELIGÊNCIA',
    ),
    _OnboardData(
      icon: Icons.insights,
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      title: 'Resultados\nmensuráveis.',
      subtitle: 'Monitore check-ins, aderência, evolução física e engajamento de cada aluno.',
      tag: 'ANALYTICS',
    ),
    _OnboardData(
      icon: Icons.rocket_launch,
      gradient: [Color(0xFFD97706), Color(0xFFB45309)],
      title: 'Seu negócio.\nSem limites.',
      subtitle: 'Controle financeiro, agenda, planos e automações — tudo em um só lugar.',
      tag: 'ESCALA',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _page.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_current < _pages.length - 1) {
      _page.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Deep animated background
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) {
                final t = _bgCtrl.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + sin(t * 2 * pi) * 0.2, -1.0),
                      end: Alignment(1.0 + cos(t * 2 * pi) * 0.2, 1.0),
                      colors: const [Color(0xFF0A0F1E), Color(0xFF0D1B5C), Color(0xFF0A0F1E)],
                    ),
                  ),
                );
              },
            ),

            // Grid
            CustomPaint(painter: _GridPainter(), size: Size.infinite),

            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.4)),
                        child: const Text('Pular', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),

                  // Pages
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (_, i) => _OnboardPageWidget(data: _pages[i]),
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Row(
                      children: [
                        // Page indicators
                        Row(
                          children: List.generate(_pages.length, (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: _current == i ? 28 : 8,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: _current == i
                                  ? EagleTokens.brand
                                  : Colors.white.withValues(alpha: 0.12),
                            ),
                          )),
                        ),
                        const Spacer(),

                        // Next/Start button
                        GestureDetector(
                          onTap: _next,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _current == _pages.length - 1 ? 160 : 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandInk]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: EagleTokens.brand.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _current == _pages.length - 1
                                  ? const Text('Começar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))
                                  : const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String tag;
  const _OnboardData({required this.icon, required this.gradient, required this.title, required this.subtitle, required this.tag});
}

class _OnboardPageWidget extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPageWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient background
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: data.gradient),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: data.gradient.first.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 10),

          // Tag badge
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: data.gradient.first.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              data.tag,
              style: TextStyle(
                color: data.gradient.first.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w600,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          Text(
            data.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
