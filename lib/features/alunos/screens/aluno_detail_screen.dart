import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_followup_store.dart';
import '../utils/altura_display.dart';
import '../providers/aluno_followup_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/fx_utils.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../health/data/health_repository.dart';
import '../../health/widgets/recovery_score_ring.dart';
import '../../avaliacao/data/avaliacao_repository.dart';
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


final aluno360Provider = FutureProvider.family<Aluno360, int>((ref, alunoId) async {
  return AlunoRepository(ref.read(apiClientProvider)).buscarAluno360(alunoId);
});

final alunoRecoveryProvider = FutureProvider.family<RecoverySnapshot?, int>((
  ref,
  alunoId,
) async {
  return HealthRepository.fromClient(
    ref.read(apiClientProvider),
  ).fetchRecoveryForAluno(alunoId);
});

/// When true, copilot card loads IA via [alunoCopilotoActionProvider] (refresh).
final alunoCopilotoForceIaProvider = StateProvider.family<bool, int>(
  (ref, alunoId) => false,
);

final alunoCopilotoActionProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, alunoId) async {
      return IaRepository(ref.read(apiClientProvider)).proximaAcao(alunoId);
    });

final alunoMedidasResumoProvider =
    FutureProvider.family<SnapshotAvaliacao?, int>((ref, alunoId) async {
      try {
        final comparativo = await AvaliacaoRepository(
          ref.read(apiClientProvider),
        ).comparativo(alunoId);
        final atual = comparativo.atual;
        final hasData =
            atual.percGordura != null ||
            (atual.massaMuscular != null && atual.massaMuscular! > 0);
        return hasData ? atual : null;
      } catch (_) {
        return null;
      }
    });

final alunoOpenIaActionsProvider =
    FutureProvider.family<List<FilaAcaoResumo>, int>((ref, alunoId) async {
      return ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActions(status: 'ABERTO', alunoId: alunoId);
    });

final alunoScoreSnapshotsProvider = FutureProvider.family<
  List<FocuxScoreSnapshotResumo>,
  int
>((ref, alunoId) async {
  return ref.read(dashboardRepositoryProvider).getFocuxScoreSnapshots(alunoId);
});

final alunoEvolucaoInteligenteProvider =
    FutureProvider.family<EvolucaoInteligente, int>((ref, alunoId) async {
      return AlunoRepository(
        ref.read(apiClientProvider),
      ).buscarEvolucaoInteligente(alunoId);
    });

final alunoTimeline360ApiProvider =
    FutureProvider.family<List<Timeline360Event>, int>((ref, alunoId) async {
      return AlunoRepository(
        ref.read(apiClientProvider),
      ).buscarTimeline360(alunoId);
    });

final alunoAderenciaSemanalProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, alunoId) async {
      return ref.read(alunoRepositoryProvider).aderenciaSemanal(alunoId);
    });

Future<void> invalidateAluno360Providers(WidgetRef ref, int alunoId) async {
  ref.invalidate(aluno360Provider(alunoId));
  ref.invalidate(alunoProvider(alunoId));
  ref.invalidate(alunoRecoveryProvider(alunoId));
  ref.invalidate(alunoAutonomiaEventosProvider(alunoId));
  ref.invalidate(alunoAutonomiaResumoProvider(alunoId));
  ref.invalidate(alunoScoreSnapshotsProvider(alunoId));
  ref.invalidate(alunoEvolucaoInteligenteProvider(alunoId));
  ref.invalidate(alunoTimeline360ApiProvider(alunoId));
  ref.read(alunoCopilotoForceIaProvider(alunoId).notifier).state = false;
  ref.invalidate(alunoCopilotoActionProvider(alunoId));
  ref.invalidate(alunoOpenIaActionsProvider(alunoId));
  ref.invalidate(alunoMedidasResumoProvider(alunoId));
  ref.invalidate(alunoAderenciaSemanalProvider(alunoId));
  await ref.read(aluno360Provider(alunoId).future);
}

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

  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir aluno'),
            content: Text(
              'Tem certeza que deseja excluir ${aluno.nome}? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await AlunoRepository(ref.read(apiClientProvider)).excluirAluno(aluno.id);
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Aluno excluído.');
        safePopOrGo(context, '/alunos');
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, 'Erro: $e');
      }
    }
  }

  Future<void> _confirmarGerarSenha(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Gerar nova senha?'),
            content: Text(
              'A senha atual de ${aluno.nome} deixará de funcionar. Gere apenas se o aluno esqueceu a senha ou precisa recuperar acesso.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FxLiquidPrimaryButton(
                expand: false,
                icon: Icons.key_rounded,
                label: 'Gerar senha',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      final senha = await AlunoRepository(
        ref.read(apiClientProvider),
      ).gerarSenhaProvisoria(aluno.id);
      ref.invalidate(alunoProvider(aluno.id));
      if (context.mounted) {
        _showNovaSenhaSheet(context, aluno, senha);
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text('Não foi possível gerar senha: $e')),
        );
      }
    }
  }

  void _showNovaSenhaSheet(BuildContext context, Aluno aluno, String senha) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final hasWhatsapp = whatsappNumber.isNotEmpty;
    final mensagem = _senhaProvisoriaMessage(aluno, senha);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: ShellSurface(
              accent: primary,
              radius: TokensStrip.rCard,
              padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 12, 20, 20),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.key_rounded, color: primary, size: 28),
                ),
                const SizedBox(height: TokensStrip.s4),
                Text(
                  'Nova senha provisória',
                  style: TextStyle(
                    color: ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A senha anterior não funciona mais. ${aluno.nome} deve trocar no primeiro acesso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mute,
                    fontSize: 13.4,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
                  decoration: fxListCardDecoration(
                    ctx,
                    accent: primary,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Senha provisória',
                        style: TextStyle(
                          color: mute,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        senha,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ink,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5.5,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Compartilhe apenas com o aluno.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mute,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      if (hasWhatsapp) {
                        final uri = Uri.parse(
                          'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(mensagem)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          return;
                        }
                      }
                      await Clipboard.setData(ClipboardData(text: mensagem));
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        FeedbackHelper.showSnackBar(
                          context,
                          SnackBar(
                            content: Text(
                              hasWhatsapp
                                  ? 'Mensagem copiada. Abra o WhatsApp e envie ao aluno.'
                                  : 'Convite copiado.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      hasWhatsapp ? Icons.send_rounded : Icons.copy_rounded,
                      size: 18,
                    ),
                    label: Text(
                      hasWhatsapp ? 'Enviar nova senha' : 'Copiar nova senha',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                if (hasWhatsapp) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: mensagem));
                        HapticFeedback.mediumImpact();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          FeedbackHelper.showSnackBar(
                            context,
                            const SnackBar(content: Text('Convite copiado.')),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: ink,
                      ),
                      label: Text(
                        'Copiar nova senha',
                        style: TextStyle(color: ink),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: chrome.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Fechar',
                      style: TextStyle(
                        color: mute,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
    );
  }

  String _senhaProvisoriaMessage(Aluno aluno, String senha) {
    final primeiroNome =
        aluno.nome.trim().isEmpty
            ? 'tudo bem'
            : aluno.nome.trim().split(RegExp(r'\s+')).first;
    return 'Olá $primeiroNome! Sua senha do Focux foi redefinida.\n\n'
        'Acesse com seu e-mail: ${aluno.email}\n'
        'Senha provisória: $senha\n\n'
        'Troque a senha no primeiro acesso.';
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
                  collapseMode: CollapseMode.pin,
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
