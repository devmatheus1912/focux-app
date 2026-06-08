import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/altura_display.dart';
import 'aluno360_ferramentas_modules_grid.dart';
import 'aluno360_ferramentas_tab.dart';
import 'aluno360_module_tile.dart';

class Aluno360DetailFerramentasTab extends ConsumerWidget {
  const Aluno360DetailFerramentasTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.perfilCompletion,
    required this.animateEntrance,
    required this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final int perfilCompletion;
  final bool animateEntrance;
  final VoidCallback onEntrancePlayed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final altura = formatAlturaDisplay(aluno.altura);
    final medidasAsync = ref.watch(alunoMedidasResumoProvider(alunoId));
    final medidas = medidasAsync.valueOrNull;
    final bf =
        medidas?.percGordura != null
            ? medidas!.percGordura!.toStringAsFixed(1)
            : null;
    final massaMagra =
        medidas?.massaMuscular != null
            ? medidas!.massaMuscular!.toStringAsFixed(1)
            : null;
    final evolucaoRoute = '/alunos/$alunoId/evolucao';

    return Aluno360FerramentasTab(
      primary: primary,
      isDark: isDark,
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      measurementsSection: medidasAsync.when(
        loading:
            () => FxLoading.sectionShimmer(context, height: 88, showHeader: false),
        error:
            (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EagleTokens.bad.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                'Medidas indisponíveis agora. Tente novamente em instantes.',
                style: TextStyle(
                  color: fxScreenMute(context),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
        data:
            (_) => LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 360 ? 2 : 4;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final needsRegistrarHint = bf == null || massaMagra == null;
                final aspectBase =
                    crossAxisCount == 2
                        ? (needsRegistrarHint ? 1.18 : 1.45)
                        : (needsRegistrarHint ? 0.82 : 1.1);
                final childAspectRatio =
                    aspectBase / textScale.clamp(1.0, 2.2);
                return Semantics(
                  container: true,
                  label: 'Medidas corporais resumidas do aluno',
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: childAspectRatio,
                    children: [
                    Aluno360MeasurementCard(
                      label: 'Idade',
                      value: (aluno.idade ?? '—').toString(),
                      unit: 'anos',
                      isDark: isDark,
                    ),
                    Aluno360MeasurementCard(
                      label: 'Altura',
                      value: altura.value,
                      unit: altura.unit,
                      isDark: isDark,
                    ),
                    Aluno360MeasurementCard(
                      label: 'BF',
                      value: bf ?? '—',
                      unit: '%',
                      isDark: isDark,
                      emptyHint: bf == null ? 'Registrar' : null,
                      onTap:
                          bf == null
                              ? () => context.push(evolucaoRoute, extra: aluno.nome)
                              : null,
                    ),
                    Aluno360MeasurementCard(
                      label: 'Massa magra',
                      value: massaMagra ?? '—',
                      unit: 'kg',
                      isDark: isDark,
                      emptyHint: massaMagra == null ? 'Registrar' : null,
                      onTap:
                          massaMagra == null
                              ? () => context.push(evolucaoRoute, extra: aluno.nome)
                              : null,
                    ),
                    ],
                  ),
                );
              },
            ),
      ),
      modulesSection: Aluno360FerramentasModulesGrid(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        perfilCompletion: perfilCompletion,
        bf: bf,
        massaMagra: massaMagra,
      ),
    );
  }
}
