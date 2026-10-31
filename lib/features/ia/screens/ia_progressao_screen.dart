import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../alunos/providers/alunos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/pt.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../features/alunos/constants/aluno_360_layout.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';
import '../providers/progressao_sugestoes_provider.dart';
import '../utils/progressao_aceitar_route_args.dart';
import '../utils/progressao_copy.dart';
import '../widgets/ia_progressao_loading_skeleton.dart';
import '../widgets/ia_progressao_pedido_card.dart';
import '../widgets/ia_quota_upgrade.dart';

class IaProgressaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const IaProgressaoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<IaProgressaoScreen> createState() => _IaProgressaoScreenState();
}

class _IaProgressaoScreenState extends ConsumerState<IaProgressaoScreen> {
  final _observacoes = TextEditingController();
  final _openedAt = DateTime.now();
  var _objetivo = ProgressaoObjetivo.hipertrofia;
  bool _loading = false;
  String? _erro;
  var _viewTracked = false;

  @override
  void initState() {
    super.initState();
    _objetivo = progressaoObjetivoDoAluno(
      ref.read(alunoProvider(widget.alunoId)).value?.objetivo,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackViewIfNeeded());
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoViewed,
      props: {'alunoId': widget.alunoId},
    );
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoTtv,
      props: {
        'alunoId': widget.alunoId,
        'ms': DateTime.now().difference(_openedAt).inMilliseconds,
      },
    );
  }

  void _showHelp() {
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoHelpOpened,
      props: {'alunoId': widget.alunoId},
    );
    showFxHelpSheet(
      context,
      title: progressaoTitulo,
      subtitle: widget.alunoNome,
      tips: const [
        FxHelpTip(
          'Dados reais',
          'A IA lê o treino ativo e as execuções das últimas 4 semanas. Você só escolhe o objetivo.',
          icon: 'target',
        ),
        FxHelpTip(
          'Opt-in',
          'Nada é gerado sozinho. A cota só é usada quando a sugestão chega.',
          icon: 'spark',
        ),
        FxHelpTip(
          'Reversível',
          'Sugestões ficam pendentes. Carga, séries e repetições só mudam se você aceitar.',
          icon: 'circle-check',
        ),
      ],
    );
  }

  void _abrirAceitar() {
    context.push(
      '/ia/progressao/aceitar',
      extra:
          ProgressaoAceitarRouteArgs(
            returnTo: '/alunos/${widget.alunoId}',
            alunoId: widget.alunoId,
            alunoNome: widget.alunoNome,
          ).toExtra(),
    );
  }

  void _abrirTreinos() {
    context.push('/alunos/${widget.alunoId}/rotina', extra: widget.alunoNome);
  }

  Future<void> _gerar() async {
    if (_loading) return;
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: progressaoConfirmTitle(),
      message: progressaoConfirmMessage(),
      icon: Icons.auto_awesome_outlined,
      confirmLabel: progressaoConfirmLabel(),
    );
    if (!ok || !mounted) return;
    AnalyticsService.instance.track(
      ProductEvents.iaProgressaoCtaTapped,
      props: {'alunoId': widget.alunoId, 'objetivo': _objetivo.api},
    );
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.progressaoCarga(
        widget.alunoId,
        objetivo: _objetivo.api,
        observacoes: _observacoes.text.trim(),
      );
      if (!mounted) return;
      ref.invalidate(progressaoSugestoesProvider(widget.alunoId));
      if (r.sugestoesRegistradas > 0) {
        _abrirAceitar();
      } else {
        setState(() => _erro = progressaoNadaParaAjustar);
      }
    } catch (e) {
      if (mounted) {
        final message =
            e is IaOperationalException
                ? e.message
                : friendlyError(
                  e,
                  fallback:
                      'Não consegui falar com a IA agora. Tente novamente em alguns segundos.',
                );
        setState(() => _erro = message);
        await IaQuotaUpgrade.handleError(context, ref, e);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final abertas =
        ref.watch(progressaoSugestoesProvider(widget.alunoId)).value ??
        const [];
    final contexto = ref.watch(progressaoContextoProvider(widget.alunoId));
    final semTreino = isSemTreinoAtivo(contexto.error);
    final semExecucao = contexto.value?.sessoes4Semanas == 0;
    final pendentes = abertas.length;

    return fxScreenA11yScope(
      label: progressaoTitulo,
      child: FxKeyboardPopScope(
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: progressaoTitulo,
            subtitle: widget.alunoNome,
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como funciona o ajuste de cargas',
                onTap: _showHelp,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s4,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s4,
                    ),
                    child: Aluno360Layout.operacaoContentWidthLimiter(
                      child: FxContentWidthLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (pendentes > 0) ...[
                              FxStripCard(
                                marca: true,
                                child: Text(
                                  pendentes == 1
                                      ? ptS.cargasEsperandoUma
                                      : ptS.cargasEsperando(pendentes),
                                  style: FocuxHubTypography.cardTitle(
                                    color: fxPaletaSobreMarca(context).ink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s3),
                            ],
                            IaProgressaoPedidoCard(
                              contexto: contexto,
                              objetivo: _objetivo,
                              onObjetivo: (o) => setState(() => _objetivo = o),
                              observacoes: _observacoes,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: TokensStrip.s3),
                            if (semExecucao) ...[
                              Text(
                                progressaoSemExecucao,
                                style: FocuxHubTypography.bodyMuted(
                                  color: chrome.mute,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s3),
                            ],
                            const IaSafetyDisclaimer(compact: true),
                            if (_erro != null) ...[
                              const SizedBox(height: TokensStrip.s4),
                              FxErrorState(
                                chromeOnDark: chrome.isDark,
                                primary: primary,
                                message: _erro!,
                                onRetry: _gerar,
                              ),
                            ],
                            if (_loading) const IaProgressaoLoadingSkeleton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pendentes > 0 && !semTreino) ...[
                        FxLiquidPrimaryButton(
                          label: ptS.cargasRevisar,
                          onPressed: _loading ? null : _abrirAceitar,
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        FxTonalButton(
                          label: ptS.cargasGerarDeNovo,
                          expanded: true,
                          onPressed: _loading || semExecucao ? null : _gerar,
                        ),
                        const SizedBox(height: TokensStrip.s1),
                        Text(
                          ptS.cargasSubstitui,
                          textAlign: TextAlign.center,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                          ),
                        ),
                      ] else
                        FxLiquidPrimaryButton(
                          label:
                              semTreino
                                  ? progressaoAbrirTreino
                                  : progressaoGerarSugestoes,
                          loading: _loading,
                          loadingLabel: progressaoStickyLoadingLabel(),
                          onPressed:
                              _loading
                                  ? null
                                  : semTreino
                                  ? _abrirTreinos
                                  : semExecucao
                                  ? null
                                  : _gerar,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
