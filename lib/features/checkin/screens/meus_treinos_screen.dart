import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/pagina.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_async_body.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../utils/treino_ficha_status.dart';

part 'meus_treinos_screen_state.part.dart';
part 'meus_treinos_screen_widgets.part.dart';

class MeusTreinosScreen extends ConsumerStatefulWidget {
  const MeusTreinosScreen({super.key});

  @override
  ConsumerState<MeusTreinosScreen> createState() => _MeusTreinosScreenState();
}

class _MeusTreinosScreenState extends ConsumerState<MeusTreinosScreen> {
  DateTime? _fetchedAt;
  int? _startingTreinoId;
  final List<ExecucaoTreino> _extra = [];
  var _page = 0;
  var _hasMore = false;
  var _loadingMore = false;
  String? _loadMoreError;

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final next = await ref
          .read(checkinRepositoryProvider)
          .meusTreinosPagina(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _extra.addAll(next.content);
        _page = next.page ?? (_page + 1);
        _hasMore = next.hasNext;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadMoreError = friendlyError(
          e,
          fallback: 'Não foi possível carregar mais treinos.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final treinosAsync = ref.watch(meusTreinosProvider);
    ref.listen<AsyncValue<Pagina<ExecucaoTreino>>>(meusTreinosProvider, (
      _,
      next,
    ) {
      next.whenData((pagina) {
        if (!mounted) return;
        setState(() {
          _extra.clear();
          _page = pagina.page ?? 0;
          _hasMore = pagina.hasNext;
          _loadMoreError = null;
          _fetchedAt = DateTime.now();
        });
      });
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final base = treinosAsync.valueOrNull?.content ?? const <ExecucaoTreino>[];
    final treinos = [...base, ..._extra];
    final count = treinosAsync.hasValue
        ? (treinosAsync.value!.totalElements ?? treinos.length)
        : treinos.length;

    return fxScreenA11yScope(
      label: 'Sua rotina',
      child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          FxKeyboardDismissScope.dismiss();
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Sua rotina',
            subtitle: FxHubFreshness.joinCount(
              meusTreinosCountLabel(count),
              treinosAsync.isLoading && base.isEmpty ? null : freshnessLabel,
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/dashboard/aluno');
            },
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(meusTreinosProvider),
                icon: Icon(Icons.refresh_rounded, color: chrome.mute),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: FxContentWidthLimiter(
              child: FxAsyncBody<Pagina<ExecucaoTreino>>(
                value: treinosAsync,
                onRetry: () => ref.invalidate(meusTreinosProvider),
                chromeOnDark: isDark,
                primary: primary,
                errorTitle: FocuxMicrocopy.naoFoiPossivelCarregar,
                skeleton: const _TrainingSkeleton(),
                isEmpty: (pagina) => pagina.content.isEmpty,
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
                builder: (context, _) {
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
                    (sum, t) =>
                        sum + t.exercicios.where((e) => e.concluido).length,
                  );
                  final itemCount =
                      treinos.length +
                      (_hasMore || _loadMoreError != null ? 1 : 0);

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
                            itemCount: itemCount,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= treinos.length) {
                                if (_loadMoreError != null) {
                                  return TextButton(
                                    onPressed: _loadMore,
                                    child: Text(_loadMoreError!),
                                  );
                                }
                                return TextButton(
                                  onPressed: _loadingMore ? null : _loadMore,
                                  child: Text(
                                    _loadingMore
                                        ? 'Carregando…'
                                        : 'Carregar mais',
                                  ),
                                );
                              }
                              return _TrainingPlanCard(
                                treino: treinos[index],
                                isDark: isDark,
                                starting:
                                    _startingTreinoId ==
                                    treinos[index].treinoId,
                                onStart: () {
                                  final treino = treinos[index];
                                  if (_startingTreinoId != null) return;
                                  setState(
                                    () => _startingTreinoId = treino.treinoId,
                                  );
                                  context.push(
                                    '/checkin/executar',
                                    extra: treino.treinoId,
                                  );
                                  Future<void>.delayed(
                                    const Duration(milliseconds: 600),
                                    () {
                                      if (!mounted) return;
                                      if (_startingTreinoId ==
                                          treino.treinoId) {
                                        setState(
                                          () => _startingTreinoId = null,
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
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
        ),
      ),
    );
  }
}
