import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_followup_store.dart';
import '../utils/altura_display.dart';
import '../providers/aluno_followup_provider.dart';
import '../providers/aluno_detail_providers.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/fx_utils.dart';
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
part 'aluno_detail_screen_operational_metrics.part.dart';
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
    final autonomiaResumoAsync = ref.watch(alunoAutonomiaResumoProvider(alunoId));
    final evolucaoGranularAsync = ref.watch(alunoEvolucaoInteligenteProvider(alunoId));
    final timelineGranularAsync = ref.watch(alunoTimeline360ApiProvider(alunoId));
    final recoveryAsync = ref.watch(alunoRecoveryProvider(alunoId));
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

          return RefreshIndicator(
            onRefresh: () => invalidateAluno360Providers(ref, alunoId),
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 196,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
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
                  collapseMode: CollapseMode.parallax,
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 72, 16, 10),
                    child: Container(
                      decoration: chrome.panel(
                        radius: TokensStrip.rCard,
                        accent: primary,
                      ),
                      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: BrandPalette.soft(primary, dark: isDark),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  fxInitials(aluno.nome),
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      aluno.nome,
                                      style: TextStyle(
                                        color: ink,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      aluno.objetivo ?? 'Emagrecimento',
                                      style: TextStyle(
                                        color: mute,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 118,
                  ),
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      _AlunoDetailOperacaoTab(
                        aluno: aluno,
                        alunoId: alunoId,
                        isDark: isDark,
                        primary: primary,
                        proximaAcao360: proximaAcao360,
                        recoveryAsync: recoveryAsync,
                        autonomiaResumoAsync: resolvedAutonomiaResumoAsync,
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
                        onMessage: () => context.push(
                          '/alunos/${aluno.id}/chat',
                          extra: aluno.nome,
                        ),
                        onEvolve: () => context.push(
                          '/alunos/${aluno.id}/ia/progressao',
                          extra: aluno.nome,
                        ),
                      ),
                      _AlunoDetailEvolucaoTab(
                        aluno: aluno,
                        alunoId: alunoId,
                        isDark: isDark,
                        ink: ink,
                        evolucaoAsync: resolvedEvolucaoAsync,
                        timeline360Async: resolvedTimelineAsync,
                      ),
                      _AlunoDetailFerramentasTab(
                        aluno: aluno,
                        alunoId: alunoId,
                        isDark: isDark,
                        primary: primary,
                        perfilCompletion: perfilCompletion,
                      ),
                    ],
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
