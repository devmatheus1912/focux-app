import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/altura_display.dart';
import 'aluno360_ferramentas_measurements_row.dart';
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
    final aderenciaSemanal =
        ref.watch(alunoAderenciaSemanalProvider(alunoId)).valueOrNull;
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
    final editarRoute = '/alunos/$alunoId/editar';
    final idadeMissing = aluno.idade == null;
    final alturaMissing = aluno.altura == null;

    return Aluno360FerramentasTab(
      primary: primary,
      isDark: isDark,
      animateEntrance: animateEntrance,
      onEntrancePlayed: onEntrancePlayed,
      measurementsSection: medidasAsync.when(
        loading:
            () => FxLoading.sectionShimmer(
              context,
              height: 88,
              showHeader: false,
            ),
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
                'Medidas indisponíveis agora. Puxe para atualizar ou tente em instantes.',
                style: Aluno360Layout.captionStyle(
                  context,
                ).copyWith(color: fxScreenMute(context), height: 1.35),
              ),
            ),
        data:
            (_) => Semantics(
              container: true,
              label: 'Medidas corporais resumidas do aluno',
              child: Aluno360FerramentasMeasurementsRow(
                cards: [
                  Aluno360MeasurementCard(
                    label: 'Idade',
                    value: (aluno.idade ?? '—').toString(),
                    unit: 'anos',
                    isDark: isDark,
                    semanticsLabel:
                        idadeMissing ? 'Idade não informada no perfil' : null,
                    emptyHint: idadeMissing ? 'Completar' : null,
                    onTap:
                        idadeMissing
                            ? () => context.push(editarRoute, extra: aluno)
                            : null,
                  ),
                  Aluno360MeasurementCard(
                    label: 'Altura',
                    value: altura.value,
                    unit: altura.unit,
                    isDark: isDark,
                    semanticsLabel:
                        alturaMissing ? 'Altura não informada no perfil' : null,
                    emptyHint: alturaMissing ? 'Completar' : null,
                    onTap:
                        alturaMissing
                            ? () => context.push(editarRoute, extra: aluno)
                            : null,
                  ),
                  Aluno360MeasurementCard(
                    label: 'Gordura',
                    value: bf ?? '—',
                    unit: '%',
                    isDark: isDark,
                    semanticsLabel:
                        bf == null
                            ? 'Percentual de gordura não registrado'
                            : 'Percentual de gordura $bf por cento',
                    emptyHint: bf == null ? 'Registrar' : null,
                    onTap:
                        bf == null
                            ? () =>
                                context.push(evolucaoRoute, extra: aluno.nome)
                            : null,
                  ),
                  Aluno360MeasurementCard(
                    label: 'Massa magra',
                    value: massaMagra ?? '—',
                    unit: 'kg',
                    isDark: isDark,
                    semanticsLabel:
                        massaMagra == null
                            ? 'Massa magra não registrada'
                            : 'Massa magra $massaMagra quilogramas',
                    emptyHint: massaMagra == null ? 'Registrar' : null,
                    onTap:
                        massaMagra == null
                            ? () =>
                                context.push(evolucaoRoute, extra: aluno.nome)
                            : null,
                  ),
                ],
              ),
            ),
      ),
      modulesSection: Aluno360FerramentasModulesGrid(
        aluno: aluno,
        alunoId: alunoId,
        isDark: isDark,
        perfilCompletion: perfilCompletion,
        bf: bf,
        massaMagra: massaMagra,
        aderenciaSemanal: aderenciaSemanal,
      ),
    );
  }
}
