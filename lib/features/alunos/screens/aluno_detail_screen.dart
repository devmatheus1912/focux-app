import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../health/data/health_repository.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/aluno_followup_provider.dart';
import '../providers/alunos_provider.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../utils/aluno_detail_aluno_actions.dart';
import '../utils/aluno_display_utils.dart';
import '../widgets/aluno360_composite_header.dart';
import '../widgets/aluno360_detail_evolucao_tab.dart';
import '../widgets/aluno360_detail_ferramentas_tab.dart';
import '../widgets/aluno360_detail_operacao_tab.dart';
import '../widgets/aluno360_operacao_sticky_cta.dart';
import '../widgets/aluno_detail_error_state.dart';
import '../widgets/aluno_detail_hero_card.dart';
import '../widgets/aluno_detail_loading_skeleton.dart';

class AlunoDetailScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final int? initialTabIndex;

  const AlunoDetailScreen({
    super.key,
    required this.alunoId,
    this.initialTabIndex,
  });

  @override
  ConsumerState<AlunoDetailScreen> createState() => _AlunoDetailScreenState();
}

class _AlunoDetailScreenState extends ConsumerState<AlunoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _entrancePlayed = false;
  String? _lastFocusSyncSignature;

  int get alunoId => widget.alunoId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    final tab = widget.initialTabIndex;
    if (tab != null && tab >= 0 && tab < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != tab) {
          _tabController.index = tab;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aluno360Async = ref.watch(aluno360Provider(alunoId));
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final tabIndex = _tabController.index;
    final autonomiaResumoAsync =
        tabIndex == 0 && !aluno360Async.hasValue
            ? ref.watch(alunoAutonomiaResumoProvider(alunoId))
            : const AsyncValue<AlunoAutonomiaResumo>.loading();
    final evolucaoGranularAsync =
        tabIndex == 1
            ? ref.watch(alunoEvolucaoInteligenteProvider(alunoId))
            : const AsyncValue<EvolucaoInteligente>.loading();
    final timelineGranularAsync =
        tabIndex == 1
            ? ref.watch(alunoTimeline360ApiProvider(alunoId))
            : const AsyncValue<List<Timeline360Event>>.loading();
    final recoveryAsync =
        tabIndex == 0
            ? ref.watch(alunoRecoveryProvider(alunoId))
            : const AsyncValue<RecoverySnapshot?>.data(null);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;

    AsyncValue<Aluno> resolvedAlunoAsync = alunoAsync;
    if (aluno360Async.hasValue) {
      resolvedAlunoAsync = AsyncData(aluno360Async.value!.aluno);
    }

    AsyncValue<AlunoAutonomiaResumo> resolvedAutonomiaResumoAsync =
        autonomiaResumoAsync;
    if (aluno360Async.hasValue) {
      resolvedAutonomiaResumoAsync = AsyncData(aluno360Async.value!.autonomiaResumo);
    }

    AsyncValue<EvolucaoInteligente> resolvedEvolucaoAsync =
        tabIndex == 1
            ? evolucaoGranularAsync
            : (aluno360Async.hasValue
                ? AsyncData(aluno360Async.value!.evolucaoInteligente)
                : evolucaoGranularAsync);

    AsyncValue<List<Timeline360Event>> resolvedTimelineAsync =
        tabIndex == 1
            ? timelineGranularAsync
            : (aluno360Async.hasValue
                ? AsyncData(aluno360Async.value!.timelinePreview)
                : timelineGranularAsync);

    final loadingPrimary = aluno360Async.isLoading && !aluno360Async.hasValue;
    final loadingFallback = resolvedAlunoAsync.isLoading && !resolvedAlunoAsync.hasValue;

    final proximaAcao360 = aluno360Async.valueOrNull?.proximaAcao;
    final showOperacaoSticky = _tabController.index == 0 && resolvedAlunoAsync.hasValue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar:
          showOperacaoSticky
              ? Aluno360OperacaoStickyCtaBar(
                aluno: resolvedAlunoAsync.value!,
                alunoId: alunoId,
                proximaAcao360: proximaAcao360,
                hasOpenCopilotTask360:
                    aluno360Async.valueOrNull?.hasOpenCopilotTask ?? false,
                isDark: isDark,
              )
              : null,
      body: loadingPrimary || loadingFallback
          ? AlunoDetailLoadingSkeleton(
              tabController: _tabController,
              isDark: isDark,
              primary: primary,
              ink: ink,
              mute: mute,
              line: chrome.line,
              sheetFill: chrome.sheetFill,
            )
          : resolvedAlunoAsync.when(
        loading:
            () => AlunoDetailLoadingSkeleton(
              tabController: _tabController,
              isDark: isDark,
              primary: primary,
              ink: ink,
              mute: mute,
              line: chrome.line,
              sheetFill: chrome.sheetFill,
            ),
        error:
            (e, _) => AlunoDetailErrorState(
              message: friendlyError(
                aluno360Async.error ?? e,
                fallback: 'Não foi possível carregar os dados do aluno.',
              ),
              onRetry: () {
                invalidateAluno360Providers(ref, alunoId);
              },
            ),
        data: (aluno) {
          ref.watch(alertasConfigProvider);
          final perfilCompletion = copilotProfileCompletion(aluno);
          final operacao = ref.watch(aluno360OperacaoProvider(alunoId));
          final compactHero =
              operacao?.contactPriority ?? isOperacaoContatoPrioritario(aluno: aluno);
          final topInset = MediaQuery.paddingOf(context).top;
          final heroBodyHeight = Aluno360Layout.heroBodyHeight(
            context,
            compactContactPriority: compactHero,
          );
          final displayName = fxTitleCaseName(aluno.nome);
          final contactPriority =
              operacao?.contactPriority ??
              isOperacaoContatoPrioritario(aluno: aluno);

          final focusSignature =
              '${aluno.id}|${aluno.operacaoFocusMode}|$contactPriority|'
              '${aluno.emRisco}|${aluno.aderenciaPercent}';
          if (_lastFocusSyncSignature != focusSignature) {
            _lastFocusSyncSignature = focusSignature;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ref
                  .read(alunoOperacaoFocusModeProvider(alunoId).notifier)
                  .syncFromAluno(
                    aluno,
                    autoDefault: shouldDefaultOperacaoFocusMode(
                      aluno: aluno,
                      contactPriority: contactPriority,
                    ),
                  );
            });
          }

          return RefreshIndicator(
            onRefresh: () => invalidateAluno360Providers(ref, alunoId),
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: Aluno360CompositeHeaderDelegate(
                  topInset: topInset,
                  heroBodyHeight: heroBodyHeight,
                  heroChild: AlunoDetailHeroCard(
                    aluno: aluno,
                    isDark: isDark,
                    primary: primary,
                    compactContactPriority: compactHero,
                    onDefineObjective:
                        alunoObjectiveIsDefined(aluno.objetivo)
                            ? null
                            : () async {
                              final updated = await context.push<bool>(
                                '/alunos/$alunoId/editar',
                                extra: aluno,
                              );
                              if (updated == true) {
                                invalidateAluno360Providers(ref, alunoId);
                              }
                            },
                  ),
                  tabController: _tabController,
                  primary: primary,
                  mute: mute,
                  line: chrome.line,
                  displayName: displayName,
                  ink: ink,
                  isDark: isDark,
                  onBack: () => safePopOrGo(context, '/alunos'),
                  onDelete: () => confirmarExclusaoAlunoDetail(context, ref, aluno),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: Aluno360Layout.tabContentGap,
                    left: Aluno360Layout.screenPadding,
                    right: Aluno360Layout.screenPadding,
                    bottom:
                        showOperacaoSticky
                            ? Aluno360Layout.operacaoScrollBottomReserve(context)
                            : MediaQuery.paddingOf(context).bottom + 8,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
                    child: switch (tabIndex) {
                      0 => Aluno360DetailOperacaoTab(
                        key: const ValueKey('aluno360_tab_operacao'),
                        aluno: aluno,
                        alunoId: alunoId,
                        isDark: isDark,
                        primary: primary,
                        proximaAcao360: proximaAcao360,
                        hasOpenCopilotTask360:
                            aluno360Async.valueOrNull?.hasOpenCopilotTask ?? false,
                        aderenciaSemanal:
                            aluno360Async.valueOrNull?.aderenciaSemanal.dias,
                        recoveryAsync: recoveryAsync,
                        autonomiaResumoAsync: resolvedAutonomiaResumoAsync,
                        animateEntrance: !_entrancePlayed,
                        onEntrancePlayed: () {
                          if (!_entrancePlayed) {
                            setState(() => _entrancePlayed = true);
                          }
                        },
                        onPassword: () => confirmarGerarSenhaAlunoDetail(context, ref, aluno),
                        onEdit: () async {
                          final updated = await context.push<bool>(
                            '/alunos/$alunoId/editar',
                            extra: aluno,
                          );
                          if (updated == true) {
                            invalidateAluno360Providers(ref, alunoId);
                          }
                        },
                        onEvolve: () => context.push(
                          '/alunos/${aluno.id}/ia/progressao',
                          extra: aluno.nome,
                        ),
                      ),
                      1 => Aluno360DetailEvolucaoTab(
                        key: const ValueKey('aluno360_tab_evolucao'),
                        aluno: aluno,
                        alunoId: alunoId,
                        isDark: isDark,
                        ink: ink,
                        evolucaoAsync: resolvedEvolucaoAsync,
                        timeline360Async: resolvedTimelineAsync,
                        animateEntrance: !_entrancePlayed,
                        onEntrancePlayed: () {
                          if (!_entrancePlayed) {
                            setState(() => _entrancePlayed = true);
                          }
                        },
                        onOpenCopilot: () => _tabController.animateTo(0),
                      ),
                      _ => Aluno360DetailFerramentasTab(
                        key: const ValueKey('aluno360_tab_ferramentas'),
                        aluno: aluno,
                        alunoId: alunoId,
                        isDark: isDark,
                        primary: primary,
                        perfilCompletion: perfilCompletion,
                        animateEntrance: !_entrancePlayed,
                        onEntrancePlayed: () {
                          if (!_entrancePlayed) {
                            setState(() => _entrancePlayed = true);
                          }
                        },
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }
}
