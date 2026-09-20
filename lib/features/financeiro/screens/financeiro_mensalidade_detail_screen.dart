import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_hub_display.dart';
import '../utils/mensalidade_surface_actions.dart';
import '../widgets/financeiro_mensalidade_help_sheet.dart';

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
      final contatos = await mensalidadeRepo(ref).listarContatos(widget.mensalidadeId);
      if (!mounted) return;
      setState(() => _contatos = contatos);
    } catch (_) {}
  }

  bool _pending(Mensalidade m) =>
      m.status == 'PENDENTE' || m.status == 'ATRASADO';

  void _leave() {
    safePopOrGo(
      context,
      '/financeiro',
      result: _changed ? 'changed' : null,
    );
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
        label:
            m == null ? 'Mensalidade' : 'Mensalidade de ${m.alunoNome}',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Mensalidade',
            subtitle: freshness,
            onBack: _leave,
            actions: [
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
                    onEdit: _editar,
                    onOpenAluno: () => context.push('/alunos/${m.alunoId}'),
                    onPix:
                        () => mostrarPixMensalidade(
                          context: context,
                          ref: ref,
                          id: m.id,
                        ),
                    onChat:
                        () => cobrarMensalidadeViaChat(
                          context: context,
                          ref: ref,
                          m: m,
                        ),
                    onContato: _contato,
                  ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.mensalidade,
    required this.contatos,
    required this.pending,
    required this.paying,
    required this.onRefresh,
    required this.onPay,
    required this.onEdit,
    required this.onOpenAluno,
    required this.onPix,
    required this.onChat,
    required this.onContato,
  });

  final Mensalidade mensalidade;
  final List<MensalidadeContato> contatos;
  final bool pending;
  final bool paying;
  final Future<void> Function() onRefresh;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onOpenAluno;
  final VoidCallback onPix;
  final VoidCallback onChat;
  final VoidCallback onContato;

  Future<void> _openMais(BuildContext context) async {
    final actions = mensalidadeDetailMaisActions(pending: pending);
    final chosen = await showFxInsetPickerSheet<MensalidadeDetailActionId>(
      context,
      title: mensalidadeDetailMaisSheetTitle(),
      items: [
        for (final id in actions)
          FxInsetPickerSheetItem(
            value: id,
            label: mensalidadeDetailActionLabel(id),
          ),
      ],
    );
    if (chosen == null || !context.mounted) return;
    switch (chosen) {
      case MensalidadeDetailActionId.aluno:
        onOpenAluno();
      case MensalidadeDetailActionId.financeiro:
        context.push('/financeiro');
      case MensalidadeDetailActionId.edit:
        onEdit();
      case MensalidadeDetailActionId.pix:
        onPix();
      case MensalidadeDetailActionId.chat:
        onChat();
      case MensalidadeDetailActionId.contato:
        onContato();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final overdue = mensalidade.status == 'ATRASADO';
    final statusColor = overdue ? EagleTokens.bad : primary;
    final status = financeiroMensalidadeStatusLabel(mensalidade.status);
    final vencimento = financeiroMensalidadeVencimentoLabel(
      mesReferencia: mensalidade.mesReferencia,
      vencimento: mensalidade.vencimento,
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
                  FxHubHeader(
                    title: mensalidade.alunoNome,
                    subtitle: financeiroMensalidadeHubSubtitle(
                      mes: financeiroMensalidadeMesPorExtenso(
                        mensalidade.mesReferencia,
                      ),
                    ),
                    onTitleTap: onOpenAluno,
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  _ValorMetricTile(
                    label: status,
                    value: mensalidade.valor.format(showDecimals: false),
                    hint: financeiroMensalidadeDetailValorHint(
                      overdue: overdue,
                      pending: pending,
                    ),
                    color: statusColor,
                    isDark: isDark,
                    emphasis:
                        overdue
                            ? OperationalMetricEmphasis.alert
                            : OperationalMetricEmphasis.normal,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: pending ? 'Referência' : 'Pago em',
                    value: financeiroMensalidadeDetailReferenciaValue(
                      pending: pending,
                      mesReferencia: mensalidade.mesReferencia,
                      pagoEm: mensalidade.pagoEm,
                    ),
                    hint: financeiroMensalidadeDetailReferenciaHint(
                      pending: pending,
                    ),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Contatos',
                    value: '${contatos.length}',
                    hint:
                        contatos.isEmpty
                            ? 'Nenhuma cobrança registrada'
                            : 'Histórico desta mensalidade',
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Vencimento',
                    value: vencimento,
                    hint: overdue ? 'Em atraso' : status,
                    color: statusColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DashboardHomeActionChip(
                      label: mensalidadeDetailMaisChipLabel(),
                      accent: primary,
                      isDark: isDark,
                      onPressed: () => _openMais(context),
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  if (contatos.isEmpty)
                    FxEmptyState(
                      icon: 'chat',
                      title: financeiroContatosEmpty(),
                      subtitle:
                          'Registre WhatsApp, ligação ou visita desta cobrança.',
                    )
                  else
                    for (final item in contatos)
                      FxSatelliteListTile(
                        title: financeiroContatoTipoLabel(item.tipo),
                        subtitle: Text(
                          financeiroContatoSubtitle(
                            item.observacao,
                            item.registradoEm,
                          ),
                        ),
                      ),
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
            child: FxLiquidPrimaryButton(
              label: pending ? 'Marcar como paga' : 'Abrir aluno',
              loading: paying,
              onPressed: paying ? null : (pending ? onPay : onOpenAluno),
            ),
          ),
        ),
      ],
    );
  }
}

/// Valor da cobrança — tabular figures / letterSpacing 0 (money).
class _ValorMetricTile extends StatelessWidget {
  const _ValorMetricTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
    required this.isDark,
    this.emphasis = OperationalMetricEmphasis.normal,
  });

  final String label;
  final String value;
  final String hint;
  final Color color;
  final bool isDark;
  final OperationalMetricEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final labelColor = Color.lerp(ink, color, isDark ? 0.22 : 0.18)!;
    final hintColor = Color.lerp(mute, ink, isDark ? 0.55 : 0.72)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: operationalMetricDecoration(
        accent: color,
        isDark: isDark,
        emphasis: emphasis,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: FocuxHubTypography.chip(labelColor).copyWith(
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: FocuxHubTypography.kpi(
              color: ink,
              fontSize: FocuxHubTypography.metricMd,
            ).copyWith(
              letterSpacing: 0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            hint,
            style: FocuxHubTypography.bodyMuted(
              color: hintColor,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
