part of 'financeiro_dashboard_screen.dart';


class _HeroRing extends StatelessWidget {
  final FinanceiroDashboard data;
  final bool isDark;

  const _HeroRing({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);

    final perc =
        data.previsaoReceita > 0
            ? (data.receitaMes / data.previsaoReceita)
            : 0.0;
    final metaSuperada =
        data.previsaoReceita > 0 && data.receitaMes >= data.previsaoReceita;

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              BrandPalette.softened(primary),
              BrandPalette.deep(primary),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.32 : 0.24),
              blurRadius: 40,
              offset: const Offset(0, 18),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Ring
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _RingChartPainter(
                      fraction: perc,
                      activeColor: primary,
                      trackColor:
                          isDark
                              ? dashboardHeroMutedOnTeal().withValues(
                                alpha: 0.08,
                              )
                              : primarySoft,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RECEBIDO',
                        style: dashboardHeroEyebrowOnTeal().copyWith(
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${(perc * 100).round()}%',
                        style: dashboardHeroMutedOnTealStyle(
                          fontWeight: FontWeight.w700,
                        ).copyWith(fontSize: 18, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metaSuperada ? 'META SUPERADA' : 'RECEBIDO NESTE MÊS',
                    style: dashboardHeroEyebrowOnTeal().copyWith(
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'R\$ ${data.receitaMes.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: dashboardHeroMutedOnTealStyle(
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 28, letterSpacing: -0.5, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Previsto ',
                          style: dashboardHeroCaptionOnTealStyle().copyWith(
                            fontSize: 12.5,
                          ),
                        ),
                        TextSpan(
                          text:
                              'R\$ ${data.previsaoReceita.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: dashboardHeroCaptionOnTealStyle(
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (data.totalInadimplentes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: EagleTokens.badSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: EagleTokens.bad,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${data.totalInadimplentes} inadimpl.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: EagleTokens.bad,
                            ),
                          ),
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

class _RingChartPainter extends CustomPainter {
  final double fraction;
  final Color activeColor;
  final Color trackColor;

  const _RingChartPainter({
    required this.fraction,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 48.0;
    const strokeWidth = 10.0;
    final trackPaint =
        Paint()
          ..color = trackColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final activePaint =
        Paint()
          ..color = activeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_RingChartPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.trackColor != trackColor;
}

class _TriGrid extends StatelessWidget {
  final FinanceiroDashboard data;
  final bool isDark;
  const _TriGrid({required this.data, required this.isDark});

  String _formatK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // Pendente = Previsão - Recebido (approx)
    final pendente = math.max(0.0, data.previsaoReceita - data.receitaMes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 22),
      child: Row(
        children: [
          Expanded(
            child: _MiniMetric(
              label: 'Pendente',
              value: 'R\$ ${_formatK(pendente)}',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniMetric(
              label: 'Ticket',
              value: 'R\$ ${data.ticketMedio.toStringAsFixed(0)}',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniMetric(
              label: 'Acumul.',
              value: 'R\$ ${_formatK(data.receitaAcumulada)}',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: mute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.mono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolucaoChart extends StatelessWidget {
  final List<EvolucaoMensalItem> items;
  final bool isDark;
  const _EvolucaoChart({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final primaryDeep = BrandPalette.deep(primary);
    final primaryAccent = BrandPalette.accent(primary);

    final maxV = items.map((e) => e.recebido).reduce(math.max);
    final chartMax = maxV <= 0 ? 100.0 : maxV;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 18, 16, 14),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Evolução · 6 meses',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: ink,
                  ),
                ),
                if (items.length > 1)
                  Builder(
                    builder: (_) {
                      final prev = items[items.length - 2].recebido;
                      final curr = items.last.recebido;
                      if (prev > 0) {
                        final diff = ((curr - prev) / prev * 100).round();
                        final sign = diff > 0 ? '+' : '';
                        return Text(
                          '$sign$diff% vs ${items[items.length - 2].mes.substring(5)}',
                          style: TextStyle(fontSize: 11, color: mute),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            const SizedBox(height: TokensStrip.s4),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children:
                    items.asMap().entries.map((e) {
                      final isLast = e.key == items.length - 1;
                      final h = (e.value.recebido / chartMax).clamp(0.05, 1.0);

                      final mes = e.value.mes;
                      final label =
                          mes.length >= 7
                              ? mes.substring(5)
                              : mes; // get just month number or string

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${(e.value.recebido / 1000).toStringAsFixed(1)}k',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isLast ? ink : mute,
                                fontWeight:
                                    isLast ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: h,
                                  widthFactor: 0.7,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                        bottom: Radius.circular(2),
                                      ),
                                      gradient:
                                          isLast
                                              ? LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors:
                                                    isDark
                                                        ? [
                                                          primaryAccent,
                                                          primary,
                                                        ]
                                                        : [
                                                          primary,
                                                          primaryDeep,
                                                        ],
                                              )
                                              : null,
                                      color:
                                          !isLast
                                              ? (isDark
                                                  ? dashboardHeroMutedOnTeal()
                                                      .withValues(alpha: 0.08)
                                                  : primarySoft)
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isLast ? ink : mute,
                                fontWeight:
                                    isLast ? FontWeight.w600 : FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VencimentoRow extends StatelessWidget {
  final VencimentoItem item;
  final bool isDark;
  const _VencimentoRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final primaryDeep = BrandPalette.deep(primary);

    final isAtrasado = item.status == 'ATRASADO';
    final color = isAtrasado ? EagleTokens.bad : EagleTokens.warn;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: fxListCardDecoration(
        context,
        accent: isAtrasado ? EagleTokens.bad : EagleTokens.warn,
        radius: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? primaryDeep : primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              item.alunoNome.isNotEmpty ? item.alunoNome[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.alunoNome,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAtrasado ? 'Atrasado' : 'Vencendo',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      ' · ${item.mesReferencia.substring(0, 7)}',
                      style: TextStyle(fontSize: 11.5, color: mute),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${item.valor.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? dashboardHeroMutedOnTeal().withValues(alpha: 0.1)
                          : primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Cobrar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
