import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — FxIntroSlides (Onboarding) — Premium V2
// Staggered entry animations, visual metric anchors, spring physics
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _page = PageController();
  int _current = 0;

  late AnimationController _entryCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleSlide;
  late Animation<double> _metricsSlide;
  late Animation<double> _fade;

  static const _pages = [
    _OBData(
      icon: Icons.fitness_center_rounded,
      title: 'Seus alunos,\nsua gestão.',
      subtitle:
          'Cadastre alunos, monte treinos e acompanhe a evolução de cada um em tempo real.',
      accent: Color(0xFF80C8FF),
      metrics: [
        _MetricChip(label: 'Alunos ativos', value: '∞', icon: Icons.people_alt_rounded),
        _MetricChip(label: 'Treinos/mês', value: '500+', icon: Icons.calendar_today_rounded),
        _MetricChip(label: 'Evolução', value: 'Real-time', icon: Icons.trending_up_rounded),
      ],
    ),
    _OBData(
      icon: Icons.auto_awesome_rounded,
      title: 'IA que\nentende treino.',
      subtitle:
          'Gere treinos e dietas personalizados em segundos. A IA aprende com o histórico de cada aluno.',
      accent: Color(0xFFA0CCFF),
      metrics: [
        _MetricChip(label: 'Geração', value: '<10s', icon: Icons.bolt_rounded),
        _MetricChip(label: 'Personalização', value: '100%', icon: Icons.tune_rounded),
        _MetricChip(label: 'Modelos IA', value: '3+', icon: Icons.psychology_rounded),
      ],
    ),
    _OBData(
      icon: Icons.attach_money_rounded,
      title: 'Financeiro\nsem complicação.',
      subtitle:
          'Cobranças, inadimplências e relatórios automatizados. Você foca no que importa: resultados.',
      accent: Color(0xFFB8D9FF),
      metrics: [
        _MetricChip(label: 'Cobranças', value: 'Auto', icon: Icons.receipt_long_rounded),
        _MetricChip(label: 'Inadimplentes', value: 'Alertas', icon: Icons.notifications_active_rounded),
        _MetricChip(label: 'Relatórios', value: 'PDF', icon: Icons.description_rounded),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupEntryAnimation();
    _entryCtrl.forward();
  }

  void _setupEntryAnimation() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _metricsSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _page.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done_v2', true);
    await prefs.remove('onboarding_done');
  }

  Future<void> _finish() async {
    await _markDone();
    if (mounted) context.go('/login');
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_current < _pages.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    _entryCtrl.forward(from: 0);
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
            // ── Background ──
            Container(
              decoration: BoxDecoration(
                gradient: EagleTokens.heroGradient(dark: true),
              ),
            ),

            // Grid pattern
            CustomPaint(painter: _AuthGridPainter(), size: Size.infinite),

            // Ambient glow — follows accent
            AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, __) => Positioned(
                top: -60,
                right: -60,
                child: Opacity(
                  opacity: _fade.value,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _pages[_current].accent.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom ambient glow
            Positioned(
              bottom: -120,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),

            // ── Content ──
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
                          onPressed: _finish,
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
                      onPageChanged: _onPageChanged,
                      itemBuilder: (_, i) => _OBPageWidget(
                        data: _pages[i],
                        iconScale: _iconScale,
                        titleSlide: _titleSlide,
                        subtitleSlide: _subtitleSlide,
                        metricsSlide: _metricsSlide,
                        fade: _fade,
                      ),
                    ),
                  ),

                  // Dots
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => GestureDetector(
                          onTap: () => _page.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          ),
                          child: _SlideDot(active: _current == i),
                        ),
                      ),
                    ),
                  ),

                  // CTA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // ── Tactile button with spring press ──
                        _SpringButton(
                          onTap: _next,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [primary, BrandPalette.deep(primary)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _current < 2
                                      ? 'Próximo →'
                                      : 'Começar agora',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_current == 2) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
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
                        const SizedBox(height: 14),
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

class _MetricChip {
  final String label, value;
  final IconData icon;
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _OBData {
  final IconData icon;
  final String title, subtitle;
  final Color accent;
  final List<_MetricChip> metrics;
  const _OBData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.metrics,
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
// PAGE WIDGET — with staggered entry animations + metric chips
// ═══════════════════════════════════════════════════════════════════════════

class _OBPageWidget extends StatelessWidget {
  final _OBData data;
  final Animation<double> iconScale;
  final Animation<double> titleSlide;
  final Animation<double> subtitleSlide;
  final Animation<double> metricsSlide;
  final Animation<double> fade;

  const _OBPageWidget({
    required this.data,
    required this.iconScale,
    required this.titleSlide,
    required this.subtitleSlide,
    required this.metricsSlide,
    required this.fade,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fade,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Animated Icon ──
            Transform.scale(
              scale: iconScale.value,
              child: Container(
                width: 96,
                height: 96,
                margin: const EdgeInsets.only(bottom: 24, top: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: 0.32),
                      blurRadius: 32,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
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
                        Icon(data.icon, color: data.accent, size: 42),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Title — staggered slide ──
            Transform.translate(
              offset: Offset(0, titleSlide.value),
              child: Opacity(
                opacity: fade.value.clamp(0.0, 1.0),
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.85,
                    height: 1.15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Subtitle — staggered slide ──
            Transform.translate(
              offset: Offset(0, subtitleSlide.value),
              child: Opacity(
                opacity: fade.value.clamp(0.0, 1.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Metric Chips — visual anchor filling dead space ──
            Transform.translate(
              offset: Offset(0, metricsSlide.value),
              child: Opacity(
                opacity: fade.value.clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: data.metrics.map((m) => Expanded(
                    child: _MetricChipWidget(metric: m, accent: data.accent),
                  )).toList(),
                ),
              ),
            ),

            const Spacer(),

            // ── Feature highlight bar ──
            Transform.translate(
              offset: Offset(0, metricsSlide.value * 0.5),
              child: Opacity(
                opacity: (fade.value * 0.8).clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: data.accent.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Usado por +200 personal trainers',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// METRIC CHIP — visual anchor replacing dead space
// ═══════════════════════════════════════════════════════════════════════════

class _MetricChipWidget extends StatelessWidget {
  final _MetricChip metric;
  final Color accent;
  const _MetricChipWidget({required this.metric, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(metric.icon, color: accent.withValues(alpha: 0.6), size: 20),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPRING BUTTON — tactile press feedback
// ═══════════════════════════════════════════════════════════════════════════

class _SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringButton({required this.child, required this.onTap});

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
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
    final p = Paint()
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
