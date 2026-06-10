import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class CheckinWorkoutHeader extends StatelessWidget {
  final String treinoNome;
  final String duration;
  final double progress;
  final int concluido;
  final int total;
  final int doneSeries;
  final int totalSeries;
  final String nextExercise;
  final Color brand;
  final Color brandDeep;
  final Color brandSoft;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;
  final VoidCallback onBack;

  const CheckinWorkoutHeader({
    super.key,
    required this.treinoNome,
    required this.duration,
    required this.progress,
    required this.concluido,
    required this.total,
    required this.doneSeries,
    required this.totalSeries,
    required this.nextExercise,
    required this.brand,
    required this.brandDeep,
    required this.brandSoft,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 58, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: chrome.headerAction(radius: 12),
                  child: Icon(Icons.chevron_left_rounded, color: ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TREINO EM ANDAMENTO',
                      style: TextStyle(
                        color: mute,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treinoNome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const CheckinLiveBadge(),
            ],
          ),
          const SizedBox(height: 20),
          ShellSurface(
            accent: brand,
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duration,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 56,
                    fontWeight: FontWeight.w600,
                    height: 0.96,
                    letterSpacing: -2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: line,
                    valueColor: AlwaysStoppedAnimation(brand),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CheckinHeaderMetric(
                        label: 'Exercicios',
                        value: '$concluido/$total',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CheckinHeaderMetric(
                        label: 'Series',
                        value:
                            totalSeries == 0
                                ? '$doneSeries'
                                : '$doneSeries/$totalSeries',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: brandSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.near_me_rounded,
                        color: brand,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proximo foco',
                            style: TextStyle(
                              color: mute,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextExercise,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckinHeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const CheckinHeaderMetric({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: fxListCardDecoration(context),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: mute,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckinLiveBadge extends StatefulWidget {
  const CheckinLiveBadge({super.key});

  @override
  State<CheckinLiveBadge> createState() => _CheckinLiveBadgeState();
}

class _CheckinLiveBadgeState extends State<CheckinLiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: EagleTokens.bad,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'AO VIVO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class CheckinPulseDot extends StatefulWidget {
  final Color color;
  const CheckinPulseDot({super.key, required this.color});

  @override
  State<CheckinPulseDot> createState() => _CheckinPulseDotState();
}

class _CheckinPulseDotState extends State<CheckinPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
