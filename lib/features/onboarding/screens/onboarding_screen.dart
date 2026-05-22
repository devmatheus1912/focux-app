import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/widgets/brand_glass_mark.dart';

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
      title: 'Seus alunos, sua ',
      titleHighlight: 'gestão.',
      subtitle:
          'Cadastre alunos, monte treinos e acompanhe a evolução de cada um em tempo real.',
      orbitIcons: [
        Icons.people_alt_rounded,
        Icons.show_chart_rounded,
        Icons.calendar_month_rounded,
      ],
      metrics: [
        _MetricChip(
          label: 'Alunos ativos',
          value: '∞',
          icon: Icons.people_alt_rounded,
        ),
        _MetricChip(
          label: 'Treinos/mês',
          value: '500+',
          icon: Icons.calendar_today_rounded,
        ),
        _MetricChip(
          label: 'Evolução',
          value: 'Real-time',
          icon: Icons.trending_up_rounded,
        ),
      ],
      features: [
        'Fichas de treino ilimitadas',
        'Acompanhamento de evolução corporal',
        'Agenda integrada com check-in',
      ],
    ),
    _OBData(
      title: 'IA que entende ',
      titleHighlight: 'treino.',
      subtitle:
          'Gere treinos e dietas personalizados em segundos. A IA aprende com o histórico de cada aluno.',
      orbitIcons: [
        Icons.psychology_rounded,
        Icons.auto_graph_rounded,
        Icons.restaurant_rounded,
      ],
      metrics: [
        _MetricChip(label: 'Geração', value: '<10s', icon: Icons.bolt_rounded),
        _MetricChip(
          label: 'Personalização',
          value: '100%',
          icon: Icons.tune_rounded,
        ),
        _MetricChip(
          label: 'Modelos IA',
          value: '3+',
          icon: Icons.psychology_rounded,
        ),
      ],
      features: [
        'Progressão automática de cargas',
        'Substituição inteligente de exercícios',
        'Copiloto com sugestões em tempo real',
      ],
    ),
    _OBData(
      title: 'Financeiro ',
      titleHighlight: 'sem complicação.',
      subtitle:
          'Cobranças, inadimplências e relatórios automatizados. Você foca no que importa: resultados.',
      orbitIcons: [
        Icons.trending_up_rounded,
        Icons.pie_chart_rounded,
        Icons.account_balance_wallet_rounded,
      ],
      metrics: [
        _MetricChip(
          label: 'Cobranças',
          value: 'Auto',
          icon: Icons.receipt_long_rounded,
        ),
        _MetricChip(
          label: 'Inadimplentes',
          value: 'Alertas',
          icon: Icons.notifications_active_rounded,
        ),
        _MetricChip(
          label: 'Relatórios',
          value: 'PDF',
          icon: Icons.description_rounded,
        ),
      ],
      features: [
        'Controle de mensalidades por aluno',
        'Alertas automáticos de inadimplência',
        'Relatório financeiro exportável',
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
    await prefs.setBool('onboarding_done_v3', true);
    await prefs.remove('onboarding_done_v2');
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
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.18),
                  radius: 1.1,
                  colors: [
                    Color(0xFF0A1F24),
                    Color(0xFF050B0D),
                    Color(0xFF050B0D),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Grid pattern
            CustomPaint(painter: _AuthGridPainter(), size: Size.infinite),

            // Soft hero glow — behind logo only
            Positioned(
              top: 108,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primary.withValues(alpha: 0.14),
                          primary.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
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
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _finish,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pular',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ],
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
                      itemBuilder:
                          (_, i) => _OBPageWidget(
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
                          onTap:
                              () => _page.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              ),
                          child: _SlideDot(
                            active: _current == i,
                            primary: primary,
                          ),
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
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [primary, BrandPalette.deep(primary)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.38),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 18,
                                  right: 18,
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.28),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _current < 2
                                            ? 'Próximo →'
                                            : 'Começar agora',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
  final String title;
  final String titleHighlight;
  final String subtitle;
  final List<_MetricChip> metrics;
  final List<String> features;
  final List<IconData> orbitIcons;
  const _OBData({
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.metrics,
    required this.features,
    required this.orbitIcons,
  });
}

class _SlideDot extends StatelessWidget {
  final bool active;
  final Color primary;
  const _SlideDot({required this.active, required this.primary});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: active ? 28 : 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color:
            active ? primary : Colors.white.withValues(alpha: 0.22),
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

  List<Widget> _buildOrbitIcons(_OBData d, Color primary) {
    const positions = [
      Alignment(-0.92, -0.72),
      Alignment(0.92, -0.28),
      Alignment(-0.78, 0.88),
    ];
    return List.generate(d.orbitIcons.length, (i) {
      return Align(
        alignment: positions[i],
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: const Color(0xFF0B1518),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
                blurRadius: 12,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(
            d.orbitIcons[i],
            size: 18,
            color: primary,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: fade,
      builder:
          (_, __) => Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: iconScale.value,
                  child: SizedBox(
                    width: 188,
                    height: 188,
                    child: CustomPaint(
                      painter: _OrbitLinksPainter(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ..._buildOrbitIcons(data, primary),
                          BrandGlassMark(
                            size: 112,
                            tone: BrandGlassTone.dark,
                            glowColor: primary,
                            shimmerAlpha: 0.12,
                            enableBackdropBlur: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Transform.translate(
                  offset: Offset(0, titleSlide.value),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                          height: 1.12,
                        ),
                        children: [
                          TextSpan(text: data.title),
                          TextSpan(
                            text: data.titleHighlight,
                            style: TextStyle(color: primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Transform.translate(
                  offset: Offset(0, subtitleSlide.value),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        data.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Transform.translate(
                  offset: Offset(0, metricsSlide.value),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: Row(
                      children:
                          data.metrics
                              .map(
                                (m) => Expanded(
                                  child: _MetricChipWidget(
                                    metric: m,
                                    primary: primary,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Transform.translate(
                  offset: Offset(0, metricsSlide.value * 0.7),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children:
                            data.features.asMap().entries.map((e) {
                              final isLast = e.key == data.features.length - 1;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 11,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white.withValues(
                                            alpha: 0.72,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Transform.translate(
                  offset: Offset(0, metricsSlide.value * 0.5),
                  child: Opacity(
                    opacity: (fade.value * 0.95).clamp(0.0, 1.0),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Usado por +200 personal trainers',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.48),
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
  final Color primary;
  const _MetricChipWidget({required this.metric, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(metric.icon, color: primary, size: 18),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.42),
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
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        builder:
            (_, child) => Transform.scale(scale: _scale.value, child: child),
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
    final p =
        Paint()
          ..color = EagleTokens.brandAccent.withValues(alpha: 0.045)
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

class _OrbitLinksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final nodes = [
      Offset(size.width * 0.14, size.height * 0.20),
      Offset(size.width * 0.86, size.height * 0.34),
      Offset(size.width * 0.20, size.height * 0.84),
    ];
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      _drawDotted(canvas, center, node, paint);
    }
  }

  void _drawDotted(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 4.0;
    const gap = 5.0;
    final delta = to - from;
    final distance = delta.distance;
    if (distance <= 0) return;
    final direction = Offset(delta.dx / distance, delta.dy / distance);
    var drawn = 0.0;
    while (drawn < distance) {
      final start = from + direction * drawn;
      final endDist = math.min(drawn + dash, distance);
      final end = from + direction * endDist;
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
