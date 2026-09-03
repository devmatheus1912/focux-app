import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../../health/data/health_repository.dart';
import '../../health/widgets/recovery_score_ring.dart';

class Aluno360RecoveryInsightCard extends StatefulWidget {
  const Aluno360RecoveryInsightCard({
    super.key,
    required this.recoveryAsync,
    required this.isDark,
    required this.primary,
  });

  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final bool isDark;
  final Color primary;

  @override
  State<Aluno360RecoveryInsightCard> createState() =>
      _Aluno360RecoveryInsightCardState();
}

class _Aluno360RecoveryInsightCardState
    extends State<Aluno360RecoveryInsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);

    return widget.recoveryAsync.when(
      loading: () => const SizedBox.shrink(),
      error:
          (_, __) => Semantics(
            label: 'Wearable indisponível',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DashboardSectionHeader(title: 'Wearable'),
                const SizedBox(height: TokensStrip.s3),
                OperationalMetricTile(
                  label: 'Wearable',
                  value: 'Indisponível',
                  hint: 'Não foi possível carregar os dados agora',
                  color: EagleTokens.warn,
                  isDark: widget.isDark,
                  emphasis: OperationalMetricEmphasis.alert,
                ),
              ],
            ),
          ),
      data: (snapshot) {
        if (snapshot == null) {
          return Semantics(
            label:
                _expanded
                    ? 'Recolher wearable não conectado'
                    : 'Wearable não conectado — toque para expandir',
            button: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DashboardSectionHeader(title: 'Wearable'),
                const SizedBox(height: TokensStrip.s3),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(12),
                  child: OperationalMetricTile(
                    label: 'Não conectado',
                    value: '—',
                    hint:
                        _expanded
                            ? 'Peça para conectar Apple Health ou Google Fit no app do aluno, se fizer sentido.'
                            : 'Apple Health ou Google Fit ainda não vinculados',
                    color: widget.primary,
                    isDark: widget.isDark,
                    emphasis: OperationalMetricEmphasis.muted,
                  ),
                ),
              ],
            ),
          );
        }

        return Semantics(
          label: 'Prontidão wearable ${snapshot.recoveryLabel}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DashboardSectionHeader(title: 'Wearable'),
              if (snapshot.recoveryHint.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  snapshot.recoveryHint,
                  style: Aluno360Layout.metaStyle(context).copyWith(color: mute),
                ),
              ],
              const SizedBox(height: TokensStrip.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: RecoveryScoreRing(
                      score: snapshot.recoveryScore,
                      color: widget.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prontidão wearable',
                          style: Aluno360Layout.metaStyle(
                            context,
                          ).copyWith(color: ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          snapshot.recoveryLabel,
                          style: Aluno360Layout.sectionTitleStyle(
                            context,
                            ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          snapshot.recoveryHint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Aluno360Layout.captionStyle(
                            context,
                          ).copyWith(color: mute, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
