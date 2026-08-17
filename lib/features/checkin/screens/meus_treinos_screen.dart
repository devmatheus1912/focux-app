import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_async_body.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'meus_treinos_screen_state.part.dart';
part 'meus_treinos_screen_widgets.part.dart';

class MeusTreinosScreen extends ConsumerWidget {
  const MeusTreinosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(meusTreinosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Sua rotina',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Sua rotina',
          subtitle: 'TREINOS',
          onBack: () => safePopOrGo(context, '/dashboard/aluno'),
          actions: [
            IconButton(
              onPressed: () => ref.invalidate(meusTreinosProvider),
              icon: Icon(Icons.refresh_rounded, color: fxScreenMute(context)),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: FxAsyncBody<List<ExecucaoTreino>>(
            value: treinosAsync,
            onRetry: () => ref.invalidate(meusTreinosProvider),
            chromeOnDark: isDark,
            primary: primary,
            errorTitle: FocuxMicrocopy.naoFoiPossivelCarregar,
            skeleton: const _TrainingSkeleton(),
            isEmpty: (treinos) => treinos.isEmpty,
            empty: FxEmptyState(
              icon: 'dumbbell',
              title: 'Nenhum treino atribuído',
              subtitle:
                  'Assim que seu personal liberar um treino, ele aparece aqui com execução guiada.',
              action: FxEmptyAction(
                label: 'Atualizar',
                onTap: () => ref.invalidate(meusTreinosProvider),
              ),
            ),
            builder: (context, treinos) {
              final ativos =
                  treinos
                      .where((t) => t.status.toUpperCase() != 'CONCLUIDO')
                      .length;
              final totalExercicios = treinos.fold<int>(
                0,
                (sum, t) => sum + t.exercicios.length,
              );
              final totalConcluidos = treinos.fold<int>(
                0,
                (sum, t) => sum + t.exercicios.where((e) => e.concluido).length,
              );

              return RefreshIndicator(
                color: primary,
                onRefresh: () async => ref.invalidate(meusTreinosProvider),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
                          18,
                        ),
                        child: _TrainingHero(
                          ativos: ativos,
                          total: treinos.length,
                          totalExercicios: totalExercicios,
                          totalConcluidos: totalConcluidos,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s5,
                        0,
                        20,
                        14,
                      ),
                      sliver: SliverList.separated(
                        itemCount: treinos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder:
                            (context, index) => _TrainingPlanCard(
                              treino: treinos[index],
                              isDark: isDark,
                              onStart:
                                  () => context.push(
                                    '/checkin/executar',
                                    extra: treinos[index].treinoId,
                                  ),
                            ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          0,
                          20,
                          110,
                        ),
                        child: _TrainingReadinessSection(
                          totalExercicios: totalExercicios,
                          totalConcluidos: totalConcluidos,
                          ativos: ativos,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
