import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class FinanceiroDashboardScreen extends ConsumerStatefulWidget {
  const FinanceiroDashboardScreen({super.key});

  @override
  ConsumerState<FinanceiroDashboardScreen> createState() =>
      _FinanceiroDashboardScreenState();
}

class _FinanceiroDashboardScreenState
    extends ConsumerState<FinanceiroDashboardScreen> {
  FinanceiroDashboard? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = FinanceiroRepository(ref.read(apiClientProvider));
      final dashboard = await repo.dashboard();
      if (mounted) {
        setState(() {
          _data = dashboard;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: FxLoading(strokeWidth: 2.5),
        ),
      );
    }
    if (_data == null) {
      final isDarkErr = Theme.of(context).brightness == Brightness.dark;
      final inkErr = isDarkErr ? EagleTokens.darkInk : EagleTokens.ink;
      final muteErr = isDarkErr ? EagleTokens.darkInkMute : EagleTokens.inkMute;
      final primaryErr = Theme.of(context).colorScheme.primary;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(
                    alpha: isDarkErr ? 0.18 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: EagleTokens.bad,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Erro ao carregar',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: inkErr,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verifique sua conexão e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muteErr, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryErr,
                  side: BorderSide(color: primaryErr.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = _data!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final primaryDeep = BrandPalette.deep(primary);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          const SizedBox(height: 16),
          // Hero — ring with received amount
          _HeroRing(data: d, isDark: isDark),

          // Tri-grid metrics
          _TriGrid(data: d, isDark: isDark),

          // Evolução — bar chart
          _EvolucaoChart(items: d.evolucaoMensal, isDark: isDark),

          // Vencimentos próximos
          if (d.vencimentosProximos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vencimentos',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Cobrar todos →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children:
                    d.vencimentosProximos
                        .map((v) => _VencimentoRow(item: v, isDark: isDark))
                        .toList(),
              ),
            ),
          ],

          // Top alunos
          if (d.topAlunos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Text(
                'Top alunos · acumulado',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                  ),
                ),
                child: Column(
                  children:
                      d.topAlunos.asMap().entries.map((e) {
                        final rank = e.key + 1;
                        final t = e.value;
                        final isLast = rank == d.topAlunos.length;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border:
                                isLast
                                    ? null
                                    : Border(
                                      bottom: BorderSide(
                                        color:
                                            isDark
                                                ? EagleTokens.darkLine
                                                : EagleTokens.line,
                                        width: 0.5,
                                      ),
                                    ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? primary.withValues(alpha: 0.18)
                                          : primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark ? primaryDeep : primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  t.alunoNome.isNotEmpty
                                      ? t.alunoNome[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t.alunoNome,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? EagleTokens.darkInk
                                            : EagleTokens.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'R\$ ${(t.totalPago / 1000).toStringAsFixed(1)}k',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? EagleTokens.darkInk
                                          : EagleTokens.ink,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _HeroRing extends StatelessWidget {
  final FinanceiroDashboard data;
  final bool isDark;

  const _HeroRing({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);

    final perc =
        data.previsaoReceita > 0
            ? (data.receitaMes / data.previsaoReceita)
            : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: line),
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
                              ? Colors.white.withValues(alpha: 0.08)
                              : primarySoft,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RECEBIDO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: ink,
                        ),
                      ),
                      Text(
                        '${(perc * 100).round()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: ink,
                        ),
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
                    'RECEBIDO NESTE MÊS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: mute,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'R\$ ${data.receitaMes.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Previsto ',
                          style: TextStyle(fontSize: 12.5, color: mute),
                        ),
                        TextSpan(
                          text:
                              'R\$ ${data.previsaoReceita.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
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
                        color:
                            isDark
                                ? const Color(0x1FFF8B8B)
                                : EagleTokens.badSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color:
                                isDark
                                    ? const Color(0xFFFF8B8B)
                                    : EagleTokens.bad,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${data.totalInadimplentes} inadimpl.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? const Color(0xFFFF8B8B)
                                      : EagleTokens.bad,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
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
            style: GoogleFonts.jetBrainsMono(
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

    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final primaryDeep = BrandPalette.deep(primary);
    final primaryAccent = BrandPalette.accent(primary);

    final maxV = items.map((e) => e.recebido).reduce(math.max);
    final chartMax = maxV <= 0 ? 100.0 : maxV;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
        ),
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
            const SizedBox(height: 16),
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
                                                  ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final primaryDeep = BrandPalette.deep(primary);

    final isAtrasado = item.status == 'ATRASADO';
    final color =
        isAtrasado
            ? (isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)
            : (isDark ? const Color(0xFFE2B46F) : EagleTokens.warn);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
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
              style: const TextStyle(
                color: Colors.white,
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
                          ? Colors.white.withValues(alpha: 0.1)
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
