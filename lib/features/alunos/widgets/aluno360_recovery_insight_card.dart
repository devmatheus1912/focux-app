import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return widget.recoveryAsync.when(
      loading: () => const SizedBox.shrink(),
      error:
          (_, __) => Semantics(
            label: 'Wearable indisponível',
            child: FxSettingsGroup(
              header: 'Wearable',
              accent: widget.primary,
              children: [
                FxSettingsTile(
                  icon: Icons.watch_off_outlined,
                  accent: EagleTokens.warn,
                  label: 'Wearable indisponível',
                  subtitle: 'Não foi possível carregar os dados agora',
                  value: '',
                  showDivider: false,
                  onTap: () => setState(() {}),
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
            child: FxSettingsGroup(
              header: 'Wearable',
              accent: widget.primary,
              children: [
                FxSettingsTile(
                  icon: Icons.watch_outlined,
                  label: 'Não conectado',
                  subtitle:
                      _expanded
                          ? 'Peça para conectar Apple Health ou Google Fit no app do aluno, se fizer sentido.'
                          : 'Apple Health ou Google Fit ainda não vinculados',
                  value: '',
                  picker: true,
                  showDivider: false,
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          );
        }

        return Semantics(
          label: 'Prontidão wearable ${snapshot.recoveryLabel}',
          child: FxSettingsGroup(
            header: 'Wearable',
            caption: snapshot.recoveryHint,
            accent: widget.primary,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
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
              ),
            ],
          ),
        );
      },
    );
  }
}
