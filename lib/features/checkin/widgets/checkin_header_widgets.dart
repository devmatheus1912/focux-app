import 'package:flutter/material.dart';

import '../../../core/theme/focux_typography.dart';
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
    return Container(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 58, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              TextButton(
                onPressed: onBack,
                child: const Text('Sair'),
              ),
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
                  style: FocuxTypography.display(color: ink).copyWith(
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

