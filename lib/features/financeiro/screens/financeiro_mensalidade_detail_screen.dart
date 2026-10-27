import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_hub_display.dart';
import '../utils/financeiro_numeros.dart';
import '../utils/mensalidade_surface_actions.dart';
import '../widgets/financeiro_mensalidade_help_sheet.dart';
import '../../../l10n/app_localizations.dart';

class FinanceiroMensalidadeDetailScreen extends ConsumerStatefulWidget {
  const FinanceiroMensalidadeDetailScreen({
    super.key,
    required this.mensalidadeId,
    this.initial,
  });

  final int mensalidadeId;
  final Mensalidade? initial;

  @override
  ConsumerState<FinanceiroMensalidadeDetailScreen> createState() =>
      _FinanceiroMensalidadeDetailScreenState();
}

class _FinanceiroMensalidadeDetailScreenState
    extends ConsumerState<FinanceiroMensalidadeDetailScreen> {
  Mensalidade? _mensalidade;
  List<MensalidadeContato> _contatos = const [];
  var _loading = false;
  var _paying = false;
  var _changed = false;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _mensalidade = widget.initial;
    if (_mensalidade == null) {
      _carregar();
    } else {
      _fetchedAt = DateTime.now();
      _carregarContatos();
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final loaded = await mensalidadeRepo(ref).buscar(widget.mensalidadeId);
      final contatos =
          loaded.contatos ??
          await mensalidadeRepo(ref).listarContatos(widget.mensalidadeId);
      if (!mounted) return;
      setState(() {
        _mensalidade = loaded;
        _contatos = contatos;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      final message = friendlyError(e);
      setState(() {
        _erro = message;
        _loading = false;
      });
      if (_mensalidade != null) {
        FeedbackHelper.showError(context, message);
      }
    }
  }

  Future<void> _carregarContatos() async {
    try {
      final contatos = await mensalidadeRepo(
        ref,
      ).listarContatos(widget.mensalidadeId);
      if (!mounted) return;
      setState(() => _contatos = contatos);
    } catch (_) {}
  }

  bool _pending(Mensalidade m) =>
      m.status == 'PENDENTE' || m.status == 'ATRASADO';

  void _leave() {
    safePopOrGo(context, '/financeiro', result: _changed ? 'changed' : null);
  }

  void _apply(Mensalidade updated) {
    setState(() {
      _mensalidade = updated;
      _changed = true;
    });
  }

  Future<void> _pagar() async {
    final m = _mensalidade;
    if (m == null || _paying) return;
    setState(() => _paying = true);
    final updated = await confirmarPagarMensalidade(
      context: context,
      ref: ref,
      m: m,
    );
    if (!mounted) return;
    setState(() => _paying = false);
    if (updated != null) _apply(updated);
  }

  Future<void> _editar() async {
    final m = _mensalidade;
    if (m == null) return;
    final updated = await showEditarMensalidadeSheet(
      context: context,
      ref: ref,
      m: m,
    );
    if (!mounted || updated == null) return;
    HapticFeedback.heavyImpact();
    FeedbackHelper.showSuccess(context, 'Mensalidade atualizada!');
    _apply(updated);
  }

  Future<void> _mudarStatus({
    required String title,
    required String message,
    required String confirmLabel,
    required String successMessage,
    required Future<Mensalidade> Function(int id) action,
    bool destructive = false,
  }) async {
    final m = _mensalidade;
    if (m == null) return;
    final ok = await showFxConfirmSheet(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!ok || !mounted) return;
    try {
      final updated = await action(m.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(context, successMessage);
      _apply(updated);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _cancelar() {
    final s = S.of(context);
    return _mudarStatus(
      title: s.mensalidadeCancelarTitulo,
      message: s.mensalidadeCancelarTexto,
      confirmLabel: s.mensalidadeCancelarConfirma,
      successMessage: s.mensalidadeCanceladaOk,
      action: mensalidadeRepo(ref).cancelar,
      destructive: true,
    );
  }

  Future<void> _desfazerPagamento() {
    final s = S.of(context);
    return _mudarStatus(
      title: s.mensalidadeDesfazerPagamentoTitulo,
      message: s.mensalidadeDesfazerPagamentoTexto,
      confirmLabel: s.mensalidadeDesfazerPagamentoConfirma,
      successMessage: s.mensalidadeDesfazerPagamentoOk,
      action: mensalidadeRepo(ref).desfazerPagamento,
    );
  }

  Future<void> _cobrar() async {
    final m = _mensalidade;
    if (m == null) return;
    final s = S.of(context);
    final via = await showFxInsetPickerSheet<_ViaCobranca>(
      context,
      title: s.financeiroCobrarEscolha,
      items: [
        FxInsetPickerSheetItem(
          value: _ViaCobranca.chat,
          label: s.financeiroCobrarChat,
          subtitle: s.financeiroCobrarChatDetalhe,
          icon: Icons.chat_bubble_outline_rounded,
        ),
        FxInsetPickerSheetItem(
          value: _ViaCobranca.pix,
          label: s.financeiroCobrarPix,
          subtitle: s.financeiroCobrarPixDetalhe,
          icon: Icons.qr_code_2_rounded,
        ),
      ],
    );
    if (via == null || !mounted) return;
    switch (via) {
      case _ViaCobranca.chat:
        await cobrarMensalidadeViaChat(context: context, ref: ref, m: m);
        await _carregarContatos();
      case _ViaCobranca.pix:
        await mostrarPixMensalidade(context: context, ref: ref, mensalidade: m);
    }
  }

  Future<void> _abrirMenu() async {
    final m = _mensalidade;
    if (m == null) return;
    final s = S.of(context);
    final acoes = mensalidadeDetailMaisActions(
      pending: _pending(m),
      pago: m.status == 'PAGO',
    );
    final cancelar = acoes.contains(MensalidadeDetailActionId.cancelar);
    final normais = [
      for (final a in acoes)
        if (a != MensalidadeDetailActionId.cancelar) a,
    ];
    const iconeDe = <MensalidadeDetailActionId, String>{
      MensalidadeDetailActionId.edit: 'article',
      MensalidadeDetailActionId.contato: 'chat',
      MensalidadeDetailActionId.aluno: 'users',
      MensalidadeDetailActionId.desfazerPagamento: 'refresh-cw',
      MensalidadeDetailActionId.cancelar: 'x',
    };
    final escolha = await showFxHomeSheet<MensalidadeDetailActionId>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        Widget tile(MensalidadeDetailActionId id, {bool ultimo = false}) =>
            FxSettingsTile(
              fxIcon: iconeDe[id]!,
              label: mensalidadeDetailActionLabel(id, s),
              value: '',
              danger: id == MensalidadeDetailActionId.cancelar,
              showDivider: !ultimo,
              onTap: () => Navigator.of(ctx).pop(id),
            );
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: TokensStrip.s4),
              FxSettingsGroup(
                children: [
                  for (final (i, a) in normais.indexed)
                    tile(a, ultimo: i == normais.length - 1),
                ],
              ),
              if (cancelar) ...[
                const SizedBox(height: TokensStrip.s3),
                FxSettingsGroup(
                  children: [
                    tile(MensalidadeDetailActionId.cancelar, ultimo: true),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
    if (escolha == null || !mounted) return;
    switch (escolha) {
      case MensalidadeDetailActionId.edit:
        await _editar();
      case MensalidadeDetailActionId.contato:
        await _contato();
      case MensalidadeDetailActionId.aluno:
        context.push('/alunos/${m.alunoId}');
      case MensalidadeDetailActionId.desfazerPagamento:
        await _desfazerPagamento();
      case MensalidadeDetailActionId.cancelar:
        await _cancelar();
    }
  }

  Future<void> _contato() async {
    final m = _mensalidade;
    if (m == null) return;
    final ok = await registrarContatoMensalidade(
      context: context,
      ref: ref,
      m: m,
    );
    if (ok) await _carregarContatos();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final m = _mensalidade;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leave();
      },
      child: fxScreenA11yScope(
        label: m == null ? 'Mensalidade' : 'Mensalidade de ${m.alunoNome}',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Mensalidade',
            subtitle: freshness,
            onBack: _leave,
            actions: [
              if (m != null) ...[
                ShellHeaderIconButton(
                  icon: 'more',
                  tooltip: S.of(context).financeiroMenuTooltip,
                  onTap: _abrirMenu,
                ),
                SizedBox(width: FxHelpChrome.gap),
              ],
              FxHelpIconButton(
                tooltip: 'Como usar esta mensalidade',
                onTap: () => showFinanceiroMensalidadeHelpSheet(context),
              ),
            ],
          ),
          body:
              _loading && m == null
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 3),
                  )
                  : _erro != null && m == null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    title: 'Não conseguimos carregar a mensalidade',
                    message: _erro!,
                    onRetry: _carregar,
                  )
                  : m == null
                  ? FxEmptyState(
                    icon: 'dollar-sign',
                    title: 'Mensalidade não encontrada',
                    subtitle: 'Puxe para atualizar ou volte ao financeiro.',
                    action: FxEmptyAction(
                      label: 'Tentar de novo',
                      onTap: _carregar,
                    ),
                  )
                  : _DetailBody(
                    mensalidade: m,
                    contatos: _contatos,
                    pending: _pending(m),
                    paying: _paying,
                    onRefresh: _carregar,
                    onPay: _pagar,
                    onCobrar: _cobrar,
                    onOpenAluno: () => context.push('/alunos/${m.alunoId}'),
                  ),
        ),
      ),
    );
  }
}

enum _ViaCobranca { chat, pix }

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.mensalidade,
    required this.contatos,
    required this.pending,
    required this.paying,
    required this.onRefresh,
    required this.onPay,
    required this.onCobrar,
    required this.onOpenAluno,
  });

  final Mensalidade mensalidade;
  final List<MensalidadeContato> contatos;
  final bool pending;
  final bool paying;
  final Future<void> Function() onRefresh;
  final VoidCallback onPay;
  final VoidCallback onCobrar;
  final VoidCallback onOpenAluno;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final selo = financeiroSelo(s, mensalidade, hoje: DateTime.now());
    final vencimento = financeiroMensalidadeVencimentoLabel(
      mesReferencia: mensalidade.mesReferencia,
      vencimento: mensalidade.vencimento,
    );
    // Letra grande: os dois botões empilham em vez de espremer o rótulo.
    final empilhar = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final cobrar = FxLiquidSecondaryButton(
      label: s.financeiroCobrar,
      onPressed: onCobrar,
    );
    final pagar = FxLiquidPrimaryButton(
      label: 'Marcar como paga',
      loading: paying,
      onPressed: paying ? null : onPay,
    );

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: FxContentWidthLimiter(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  24,
                ),
                children: [
                  _CartaoMensalidade(
                    mensalidade: mensalidade,
                    seloTexto: selo.texto,
                    seloTom: selo.tom,
                    vencimento:
                        pending ? s.financeiroVenceEm(vencimento) : null,
                    onOpenAluno: onOpenAluno,
                  ),
                  if (contatos.isNotEmpty) ...[
                    const SizedBox(height: TokensStrip.s4),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        bottom: TokensStrip.s2,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          s.financeiroCobrancasFeitas,
                          style: TextStyle(
                            color: chrome.mute,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    for (final item in contatos)
                      FxSatelliteListTile(
                        title: financeiroContatoTipoLabel(item.tipo),
                        titleCase: false,
                        subtitle: Text(
                          financeiroContatoSubtitle(
                            item.observacao,
                            item.registradoEm,
                          ),
                        ),
                      ),
                  ],
                ],
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
            child:
                !pending
                    ? FxLiquidPrimaryButton(
                      label: 'Abrir aluno',
                      onPressed: onOpenAluno,
                    )
                    : empilhar
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pagar,
                        const SizedBox(height: TokensStrip.s2),
                        cobrar,
                      ],
                    )
                    : Row(
                      children: [
                        Expanded(child: cobrar),
                        const SizedBox(width: TokensStrip.s2),
                        Expanded(flex: 2, child: pagar),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}

/// Um cartão só: quem, quanto, de que mês e em que estado está.
class _CartaoMensalidade extends StatelessWidget {
  const _CartaoMensalidade({
    required this.mensalidade,
    required this.seloTexto,
    required this.seloTom,
    required this.vencimento,
    required this.onOpenAluno,
  });

  final Mensalidade mensalidade;
  final String seloTexto;
  final FxPillTone seloTom;

  /// "Vence em 05/11/2026"; só para cobrança em aberto.
  final String? vencimento;
  final VoidCallback onOpenAluno;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: BoxDecoration(
        color: chrome.cardFill,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: chrome.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenAluno,
            borderRadius: BorderRadius.circular(TokensStrip.rInput),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      mensalidade.alunoNome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FxIcon(name: 'chevron-right', size: 16, color: chrome.mute),
                ],
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          FxStatusPill(label: seloTexto, tone: seloTom),
          const SizedBox(height: TokensStrip.s3),
          Text(
            mensalidade.valor.formatCobranca(),
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ).copyWith(
              letterSpacing: 0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            financeiroMensalidadeMesPorExtenso(mensalidade.mesReferencia),
            style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
          ),
          if (vencimento != null)
            Text(
              vencimento!,
              style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
            ),
        ],
      ),
    );
  }
}
