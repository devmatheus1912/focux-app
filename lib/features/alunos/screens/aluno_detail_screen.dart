import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_followup_store.dart';
import '../utils/altura_display.dart';
import '../providers/aluno_followup_provider.dart';
import '../providers/aluno_detail_providers.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../health/data/health_repository.dart';
import '../../health/widgets/recovery_score_ring.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/theme/shell_chrome.dart';
import '../constants/aluno_360_layout.dart';
import '../widgets/aluno_detail_hero_card.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
part 'aluno_detail_screen_hero.part.dart';
part 'aluno_detail_screen_copilot.part.dart';
part 'aluno_detail_screen_evolucao.part.dart';
part 'aluno_detail_screen_timeline.part.dart';
part 'aluno_detail_screen_shared_widgets.part.dart';
part 'aluno_detail_screen_modules.part.dart';
part 'aluno_detail_screen_recovery.part.dart';
part 'aluno_detail_screen_operational.part.dart';
part 'aluno_detail_screen_weight.part.dart';
part 'aluno_detail_screen_follow_up.part.dart';
part 'aluno_detail_screen_shared.part.dart';
part 'aluno_detail_screen_tabs.part.dart';
part 'aluno_detail_actions.part.dart';

class AlunoDetailScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const AlunoDetailScreen({super.key, required this.alunoId});

  @override
  ConsumerState<AlunoDetailScreen> createState() => _AlunoDetailScreenState();
}

class _AlunoDetailScreenState extends ConsumerState<AlunoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _entrancePlayed = false;

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
        tabIndex == 1 && !aluno360Async.hasValue
            ? ref.watch(alunoEvolucaoInteligenteProvider(alunoId))
            : const AsyncValue<EvolucaoInteligente>.loading();
    final timelineGranularAsync =
        tabIndex == 1 && !aluno360Async.hasValue
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

    AsyncValue<EvolucaoInteligente> resolvedEvolucaoAsync = evolucaoGranularAsync;
    if (aluno360Async.hasValue) {
      resolvedEvolucaoAsync = AsyncData(aluno360Async.value!.evolucaoInteligente);
    }

    AsyncValue<List<Timeline360Event>> resolvedTimelineAsync = timelineGranularAsync;
    if (aluno360Async.hasValue) {
      resolvedTimelineAsync = AsyncData(aluno360Async.value!.timelinePreview);
    }

    final loadingPrimary = aluno360Async.isLoading && !aluno360Async.hasValue;
    final loadingFallback = resolvedAlunoAsync.isLoading && !resolvedAlunoAsync.hasValue;

    final proximaAcao360 = aluno360Async.valueOrNull?.proximaAcao;
    final showOperacaoSticky = _tabController.index == 0 && resolvedAlunoAsync.hasValue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar:
          showOperacaoSticky
              ? _OperacaoStickyCtaBar(
                aluno: resolvedAlunoAsync.value!,
                alunoId: alunoId,
                proximaAcao360: proximaAcao360,
                isDark: isDark,
              )
              : null,
      body: loadingPrimary || loadingFallback
          ? const FxLoading()
          : resolvedAlunoAsync.when(
        loading: () => const FxLoading(),
        error:
            (e, _) => _AlunoDetailErrorState(
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
          final perfilCompletion = _perfilCompletion(aluno);
          final heroExpandedHeight = Aluno360Layout.heroExpandedHeight(context);

          return RefreshIndicator(
            onRefresh: () => invalidateAluno360Providers(ref, alunoId),
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: heroExpandedHeight,
                pinned: true,
                stretch: false,
                backgroundColor: chrome.sheetFill,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 2,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: IconButton(
                    onPressed: () => safePopOrGo(context, '/alunos'),
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: chrome.headerAction(radius: 12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isDark
                              ? primary.withValues(alpha: 0.18)
                              : BrandPalette.softer(primary),
                          chrome.sheetFill,
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        MediaQuery.paddingOf(context).top + kToolbarHeight + 2,
                        TokensStrip.s4,
                        6,
                      ),
                      child: AlunoDetailHeroCard(
                        aluno: aluno,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, color: ink),
                    tooltip: 'Mais opções',
                    onSelected: (value) async {
                      if (value == 'excluir') {
                        await _confirmarExclusao(context, ref, aluno);
                      }
                    },
                    itemBuilder:
                        (ctx) => const [
                          PopupMenuItem(
                            value: 'excluir',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: EagleTokens.bad,
                              ),
                              title: Text(
                                'Excluir aluno',
                                style: TextStyle(color: EagleTokens.bad),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                  ),
                  const ShellThemeToggle(size: 38),
                  const SizedBox(width: 8),
                ],
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _AlunoDetailTabBarDelegate(
                  tabController: _tabController,
                  primary: primary,
                  mute: mute,
                  line: chrome.line,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 12,
                    left: 16,
                    right: 16,
                    bottom: showOperacaoSticky
                        ? Aluno360Layout.operacaoScrollBottomReserve(context)
                        : 24,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
                    child: switch (tabIndex) {
                      0 => _AlunoDetailOperacaoTab(
                        key: const ValueKey('aluno360_tab_operacao'),
                        aluno: aluno,
                        alunoId: alunoId,
                        isDark: isDark,
                        primary: primary,
                        proximaAcao360: proximaAcao360,
                        hasOpenCopilotTask360:
                            aluno360Async.valueOrNull?.hasOpenCopilotTask ?? false,
                        recoveryAsync: recoveryAsync,
                        autonomiaResumoAsync: resolvedAutonomiaResumoAsync,
                        animateEntrance: !_entrancePlayed,
                        onEntrancePlayed: () {
                          if (!_entrancePlayed) {
                            setState(() => _entrancePlayed = true);
                          }
                        },
                        onPassword: () => _confirmarGerarSenha(context, ref, aluno),
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
                      1 => _AlunoDetailEvolucaoTab(
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
                      ),
                      _ => _AlunoDetailFerramentasTab(
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

int _perfilCompletion(Aluno aluno) {
  final fields = [
    aluno.nome,
    aluno.email,
    aluno.telefone,
    aluno.whatsapp,
    aluno.objetivo,
    aluno.genero,
    aluno.tipoConsultoria,
  ];
  final filled = fields.where((value) {
    if (value == null) return false;
    return value.trim().isNotEmpty;
  }).length;
  return ((filled / fields.length) * 100).round().clamp(0, 100);
}
