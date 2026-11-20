import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_aluno_estado.dart';
import '../utils/financeiro_hub_display.dart';
import '../../recorrencia/data/recorrencia_repository.dart';
import '../../recorrencia/utils/recorrencia_display.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../utils/mensalidade_surface_actions.dart';
import '../widgets/financeiro_aluno_cobranca_sheet.dart';
import '../widgets/financeiro_aluno_help_sheet.dart';
import '../../../core/theme/fx_icons.dart';

class FinanceiroAlunoScreen extends ConsumerStatefulWidget {
  const FinanceiroAlunoScreen({super.key});

  @override
  ConsumerState<FinanceiroAlunoScreen> createState() =>
      _FinanceiroAlunoScreenState();
}

class _FinanceiroAlunoScreenState extends ConsumerState<FinanceiroAlunoScreen> {
  List<Mensalidade> _mensalidades = [];
  var _page = 0;
  var _hasMore = false;
  var _loading = true;
  var _carregandoMais = false;
  String? _erro;
  DateTime? _fetchedAt;
  RecorrenciaAssinatura? _automatico;

  @override
  void initState() {
    super.initState();
    _carregar();
    _carregarAutomatico();
  }

  /// Pagamento automático do aluno; sem ele (ou com erro), a linha não aparece.
  Future<void> _carregarAutomatico() async {
    try {
      final a =
          await RecorrenciaRepository(ref.read(apiClientProvider)).minha();
      if (mounted) setState(() => _automatico = a);
    } catch (_) {}
  }

  Future<void> _carregar() async {
    if (_fetchedAt != null) unawaited(_carregarAutomatico());
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final result =
          await FinanceiroRepository(
            ref.read(apiClientProvider),
          ).minhasMensalidades();
      if (!mounted) return;
      _aplicar(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _aplicar(MensalidadesPage result) {
    setState(() {
      _mensalidades = result.mensalidades;
      _page = result.page;
      _hasMore = result.hasMore;
      _fetchedAt = DateTime.now();
      _loading = false;
      _erro = null;
    });
  }

  /// Sem skeleton e sem voltar à página 0; erro vira toast.
  Future<void> _recarregarMantendoPaginas() async {
    try {
      final result = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).minhasMensalidadesAte(_page);
      if (!mounted) return;
      _aplicar(result);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _pagarPix(Mensalidade item) async {
    final interagiu = await mostrarPixMensalidade(
      context: context,
      ref: ref,
      mensalidade: item,
      asAluno: true,
    );
    if (interagiu && mounted) await _recarregarMantendoPaginas();
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final next = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).minhasMensalidades(page: _page + 1);
      if (!mounted) return;
      final seen = _mensalidades.map((m) => m.id).toSet();
      setState(() {
        _mensalidades = [
          ..._mensalidades,
          ...next.mensalidades.where((m) => seen.add(m.id)),
        ];
        _page = next.page;
        _hasMore = next.hasMore;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  FinanceiroAlunoEstado get _estado =>
      financeiroAlunoEstado(_mensalidades, parcial: _hasMore);

  /// Cartão de estado: deve algo? quanto e quando.
  Widget _cartaoEstado(FinanceiroAlunoEstado estado) {
    final chrome = ShellChrome.of(context);
    final atrasado = estado.situacao == FinanceiroAlunoSituacao.atrasado;
    final corTitulo =
        atrasado ? EagleTokens.semanticBad(isDark: chrome.isDark) : chrome.ink;
    return FxStripCard(
      emphasize: atrasado,
      accent: atrasado ? EagleTokens.bad : null,
      child: Semantics(
        container: true,
        label: '${estado.titulo}. ${estado.linha}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              estado.titulo,
              style:
                  estado.situacao == FinanceiroAlunoSituacao.emDia
                      ? FocuxHubTypography.sectionTitle(context, color: corTitulo)
                      : FocuxHubTypography.metric(color: corTitulo),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              estado.linha,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
        ),
      ),
    );
  }

  /// Linha do Pagamento automático (só quando existe).
  Widget? _linhaAutomatico() {
    final a = _automatico;
    if (a == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s2),
      child: FxSatelliteListTile(
        title: 'Pagamento automático',
        titleCase: false,
        leading: const Icon(FxIcons.atualizar, size: 18),
        trailing: Text(
          recorrenciaAlunoStatusCurto(status: a.status, initPoint: a.initPoint),
          style: FocuxHubTypography.bodyMuted(
            color: fxScreenMute(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: () async {
          await context.push('/aluno/recorrencia');
          if (mounted) await _carregarAutomatico();
        },
      ),
    );
  }

  List<Widget> _topo(FinanceiroAlunoEstado estado) {
    final automatico = _linhaAutomatico();
    return [
      _cartaoEstado(estado),
      if (automatico != null) automatico,
      const SizedBox(height: TokensStrip.s4),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final pronto = !_loading && _erro == null;
    final estado = _estado;
    final paraPagar = estado.paraPagar;
    final automatico = _linhaAutomatico();

    return fxScreenA11yScope(
      label: 'Minhas mensalidades',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/dashboard/aluno');
        },
        child: FxShellScaffold(
          comFundo: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Mensalidades',
            subtitle:
                pronto && _mensalidades.isNotEmpty
                    ? FxHubFreshness.joinCount(estado.subtituloTopo, freshness)
                    : freshness,
            onBack: () => safePopOrGo(context, '/dashboard/aluno'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar suas mensalidades',
                onTap: () => showFinanceiroAlunoHelpSheet(context),
              ),
            ],
          ),
          // Em aberto: pagar é a ação; em dia, não há rodapé.
          bottomNavigationBar:
              pronto && paraPagar != null
                  ? FxFormStickyBar(
                    child: FxLiquidPrimaryButton(
                      label: 'Pagar com PIX',
                      onPressed: () => _pagarPix(paraPagar),
                    ),
                  )
                  : null,
          body: FxContentWidthLimiter(
            child:
                _loading
                    ? const Padding(
                      padding: EdgeInsets.only(top: TokensStrip.s4),
                      child: SkeletonList(count: 5),
                    )
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: isDark,
                      primary: primary,
                      title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      message: _erro!,
                      onRetry: _carregar,
                    )
                    : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          TokensStrip.s4,
                          FxSettingsLayout.pageInset,
                          32,
                        ),
                        children: [
                          if (_mensalidades.isEmpty) ...[
                            if (automatico != null) automatico,
                            FxEmptyState(
                              icon: FxIcons.dinheiro,
                              title: 'Nenhuma mensalidade',
                              subtitle:
                                  'Quando seu personal lançar uma cobrança, ela aparece aqui.',
                            ),
                          ] else ...[
                            ..._topo(estado),
                            for (final item in _mensalidades)
                              _linhaMensalidade(item, primary),
                            if (_hasMore) ...[
                              const SizedBox(height: TokensStrip.s2),
                              FxTonalButton(
                                label:
                                    _carregandoMais
                                        ? 'Carregando…'
                                        : 'Carregar mais',
                                expanded: true,
                                onPressed: _carregandoMais ? null : _carregarMais,
                              ),
                            ],
                          ],
                          if (paraPagar == null) ...[
                            const SizedBox(height: TokensStrip.s3),
                            Align(
                              child: FxTonalButton(
                                label: 'Falar com o personal',
                                icon: FxIcons.chat,
                                compact: true,
                                onPressed:
                                    () => openAlunoRoute(context, '/chat/aluno'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _linhaMensalidade(Mensalidade item, Color primary) {
    final overdue = item.status == 'ATRASADO';
    final aberta = item.status == 'PENDENTE' || overdue;
    return FxSatelliteListTile(
      title: financeiroMensalidadeTitulo(item),
      titleCase: false,
      onTap:
          () => showFinanceiroAlunoCobrancaSheet(
            context,
            item: item,
            onFalar: () => context.push('/chat/aluno'),
            onPagarPix: aberta ? () => _pagarPix(item) : null,
          ),
      subtitle: Text(financeiroMensalidadeStatusLabel(item.status)),
      accent: overdue ? EagleTokens.bad : primary,
      leading: Icon(
        overdue
            ? FxIcons.alerta
            : item.status == 'PAGO'
            ? FxIcons.concluido
            : FxIcons.dinheiro,
        size: 18,
        color: overdue ? EagleTokens.bad : primary,
      ),
      trailing: Text(
        item.valor.formatCobranca(),
        style: FocuxHubTypography.metric(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
