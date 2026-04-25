import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = dark ? EagleTokens.brandAccent : EagleTokens.brand;

    final metricas = [
      {'label': 'MRR', 'value': 'R\$ 8.420', 'delta': '+14%', 'up': true},
      {'label': 'Churn', 'value': '4,2%', 'delta': '-1,1%', 'up': true},
      {'label': 'LTV', 'value': 'R\$ 2.340', 'delta': '+8%', 'up': true},
      {'label': 'CAC', 'value': 'R\$ 42', 'delta': '-12%', 'up': true},
    ];

    final barData = [4.2, 5.1, 5.8, 6.2, 7.4, 8.4];
    final barLabels = ['nov', 'dez', 'jan', 'fev', 'mar', 'abr'];
    final maxBar = barData.reduce(max);
    final churnData = [7.2, 6.8, 6.1, 5.4, 5.1, 4.2];

    final topAlunos = [
      {'nome': 'Rafael Medeiros', 'ltv': 'R\$ 2.700'},
      {'nome': 'Beatriz Carvalho', 'ltv': 'R\$ 2.280'},
      {'nome': 'Juliana Torres', 'ltv': 'R\$ 1.900'},
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 54),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ENTERPRISE', style: TextStyle(color: brand, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text('Analytics', style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: line)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, color: mute, size: 13),
                  const SizedBox(width: 5),
                  Text('6 meses', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),

          // 4-metric grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              children: metricas.map((m) {
                final up = m['up'] as bool;
                final cCor = up ? (dark ? const Color(0xFF6FE296) : EagleTokens.good) : (dark ? const Color(0xFFFF8B8B) : EagleTokens.bad);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['label'] as String, style: TextStyle(color: mute, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    const Spacer(),
                    Text(m['value'] as String, style: TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(up ? Icons.trending_up : Icons.trending_down, color: cCor, size: 14),
                      const SizedBox(width: 4),
                      Text(m['delta'] as String, style: TextStyle(color: cCor, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('vs mês passado', style: TextStyle(color: mute, fontSize: 10)),
                    ]),
                  ]),
                );
              }).toList(),
            ),
          ),

          // MRR chart
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Receita recorrente (MRR)', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('+100% em 6m', style: TextStyle(color: dark ? const Color(0xFF6FE296) : EagleTokens.good, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: barData.asMap().entries.map((e) {
                      final h = e.value / maxBar;
                      final isLast = e.key == barData.length - 1;
                      return Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text('${e.value}k', style: TextStyle(color: isLast ? ink : mute, fontSize: 9.5, fontWeight: isLast ? FontWeight.w700 : FontWeight.w400)),
                          const SizedBox(height: 5),
                          Expanded(child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: h,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: isLast
                                      ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: dark ? [const Color(0xFF8DA4E2), const Color(0xFF3D5FBE)] : [EagleTokens.brand, EagleTokens.brandInk])
                                      : null,
                                  color: isLast ? null : (dark ? const Color(0x338DA4E2) : EagleTokens.brandSoft),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
                                ),
                              ),
                            ),
                          )),
                          const SizedBox(height: 5),
                          Text(barLabels[e.key], style: TextStyle(color: isLast ? ink : mute, fontSize: 10, fontWeight: isLast ? FontWeight.w700 : FontWeight.w400)),
                        ]),
                      ));
                    }).toList(),
                  ),
                ),
              ]),
            ),
          ),

          // Churn sparkline
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Taxa de churn', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: dark ? const Color(0x1E6FE296) : EagleTokens.goodSoft, borderRadius: BorderRadius.circular(999)),
                    child: Row(children: [
                      Icon(Icons.trending_down, color: dark ? const Color(0xFF6FE296) : EagleTokens.good, size: 12),
                      const SizedBox(width: 4),
                      Text('Caindo', style: TextStyle(color: dark ? const Color(0xFF6FE296) : EagleTokens.good, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                SizedBox(
                  height: 68, width: double.infinity,
                  child: CustomPaint(painter: _SparklinePainter(data: churnData, color: dark ? const Color(0xFF6FE296) : EagleTokens.good)),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('nov · 7,2%', style: TextStyle(color: mute, fontSize: 11)),
                  Text('abr · 4,2%', style: TextStyle(color: dark ? const Color(0xFF6FE296) : EagleTokens.good, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),

          // Top LTV
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('Top 3 · LTV', style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: topAlunos.asMap().entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
                child: Row(children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: dark ? const Color(0x268DA4E2) : EagleTokens.brandSoft, shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}', style: TextStyle(color: brand, fontSize: 12, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(radius: 18, backgroundColor: dark ? EagleTokens.darkLine : EagleTokens.line, child: Text(e.value['nome']![0], style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value['nome']!, style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w500))),
                  Text(e.value['ltv']!, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              );
            }).toList()),
          ),
        ]),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.reduce(max);
    final minV = data.reduce(min);
    final range = maxV - minV;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (((data[i] - minV) / (range == 0 ? 1 : range)) * size.height * 0.8) - (size.height * 0.1);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
