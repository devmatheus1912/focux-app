part of 'onboarding_screen.dart';

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
  const _OBData({
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.metrics,
    required this.features,
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
        color: active ? primary : heroTealSurface(0.22),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE WIDGET — with staggered entry animations + metric chips
// ═══════════════════════════════════════════════════════════════════════════

class _OBPageWidget extends StatelessWidget {
  final int pageIndex;
  final OnboardingPersona persona;
  final _OBData data;
  final bool compact;
  final Animation<double> iconScale;
  final Animation<double> titleSlide;
  final Animation<double> subtitleSlide;
  final Animation<double> metricsSlide;
  final Animation<double> fade;

  const _OBPageWidget({
    super.key,
    required this.pageIndex,
    required this.persona,
    required this.data,
    required this.compact,
    required this.iconScale,
    required this.titleSlide,
    required this.subtitleSlide,
    required this.metricsSlide,
    required this.fade,
  });

  Widget _buildHero() {
    if (pageIndex == 0) {
      final width =
          compact
              ? (persona == OnboardingPersona.aluno ? 108.0 : 112.0)
              : (persona == OnboardingPersona.aluno ? 128.0 : 132.0);
      return FocuxOfficialLogo.full(width: width);
    }
    return FocuxOfficialLogo.full(width: compact ? 104.0 : 118.0);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final titleSize =
        pageIndex == 0 ? (compact ? 24.0 : 26.0) : (compact ? 25.0 : 27.0);
    final showMetrics = pageIndex == 0 && !compact;

    return AnimatedBuilder(
      animation: fade,
      builder:
          (_, __) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              pageIndex == 0 ? (compact ? 0 : 2) : (compact ? 6 : 10),
              20,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: iconScale.value,
                  alignment: Alignment.center,
                  child: _buildHero(),
                ),

                if (pageIndex == 0) ...[
                  SizedBox(height: compact ? 4 : 8),
                  Transform.translate(
                    offset: Offset(0, subtitleSlide.value * 0.5),
                    child: Opacity(
                      opacity: fade.value.clamp(0.0, 1.0),
                      child: _OnboardingHook(
                        primary: primary,
                        aluno: persona == OnboardingPersona.aluno,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: pageIndex == 0 ? (compact ? 8 : 12) : 14),

                Transform.translate(
                  offset: Offset(0, titleSlide.value),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.inter(
                          color: heroTealInk(),
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                          height: 1.14,
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

                const SizedBox(height: 8),

                Transform.translate(
                  offset: Offset(0, subtitleSlide.value),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        data.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          color: heroTealSurface(0.86),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.48,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: pageIndex == 0 ? (compact ? 10 : 14) : 12),

                if (showMetrics)
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

                if (showMetrics) const SizedBox(height: 10),

                Transform.translate(
                  offset: Offset(0, metricsSlide.value * 0.7),
                  child: Opacity(
                    opacity: fade.value.clamp(0.0, 1.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: pageIndex == 0 ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: heroTealSurface(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: heroTealSurface(0.10),
                        ),
                      ),
                      child: Column(
                        children:
                            data.features.asMap().entries.map((e) {
                              final isLast = e.key == data.features.length - 1;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 9,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: AppTypography.inter(
                                          color: heroTealInk().withValues(
                                            alpha: 0.82,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.38,
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
              ],
            ),
          ),
    );
  }
}

class _OnboardingSocialProof extends StatelessWidget {
  const _OnboardingSocialProof({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: FocuxBrandCopy.onboardingSocialProof,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: heroTealSurface(0.04),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: heroTealSurface(0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 14, color: primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                FocuxBrandCopy.onboardingSocialProof,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: heroTealSurface(0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHook extends StatelessWidget {
  const _OnboardingHook({required this.primary, this.aluno = false});

  final Color primary;
  final bool aluno;

  @override
  Widget build(BuildContext context) {
    final hook =
        aluno
            ? FocuxBrandCopy.onboardingHookAluno
            : FocuxBrandCopy.onboardingHook;
    final highlight =
        aluno
            ? FocuxBrandCopy.onboardingHookAlunoHighlight
            : FocuxBrandCopy.onboardingHookHighlight;
    final prefix = hook.substring(0, hook.length - highlight.length);

    return Semantics(
      label: hook,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.inter(
              color: heroTealSurface(0.88),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              letterSpacing: 0.06,
            ),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                text: highlight,
                style: TextStyle(
                  color: primary.withValues(alpha: 0.95),
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
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: heroTealSurface(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: heroTealSurface(0.08)),
      ),
      child: Column(
        children: [
          Icon(metric.icon, color: primary, size: 18),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: AppTypography.inter(
              color: heroTealInk(),
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
            style: AppTypography.inter(
              color: heroTealSurface(0.78),
              fontSize: 10.5,
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
