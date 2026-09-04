import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
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
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final loaded = await mensalidadeRepo(ref).buscar(widget.mensalidadeId);
      if (!mounted) return;
      setState(() {
        _mensalidade = loaded;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final m = _mensalidade;

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
                    padding: EdgeInsets.only(top: TokensStrip.s4),
                    child: SkeletonList(count: 3),
                  )
                  : _erro != null && m == null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: _erro!,
                    onRetry: _carregar,
                  )
                  : m == null
                  ? const SizedBox.shrink()
                  : _DetailBody(
                    mensalidade: m,
                    freshnessLabel: FxHubFreshness.fromFetchedAt(_fetchedAt),
                    pending: _pending(m),
                    paying: _paying,
                    onPay: _pagar,
                    onEdit: _editar,
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
                    onContato:
                        () => registrarContatoMensalidade(
                          context: context,
                          ref: ref,
                          m: m,
                        ),
                  ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.mensalidade,
    required this.freshnessLabel,
    required this.pending,
    required this.paying,
    required this.onPay,
    required this.onEdit,
    required this.onPix,
    required this.onChat,
    required this.onContato,
  });

  final Mensalidade mensalidade;
  final String? freshnessLabel;
  final bool pending;
  final bool paying;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onPix;
  final VoidCallback onChat;
  final VoidCallback onContato;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final overdue = mensalidade.status == 'ATRASADO';
    final statusColor = overdue ? EagleTokens.bad : primary;
    final mes = financeiroMensalidadeMesPorExtenso(mensalidade.mesReferencia);
    final status = financeiroMensalidadeStatusLabel(mensalidade.status);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s4,
              FxSettingsLayout.pageInset,
              24,
            ),
            children: [
              FxHubHeader(
                title: mensalidade.alunoNome,
                freshnessLabel: freshnessLabel,
                subtitle: mes,
              ),
              const SizedBox(height: TokensStrip.s4),
              OperationalMetricTile(
                label: status,
                value: mensalidade.valor.format(showDecimals: false),
                hint: mes,
                color: statusColor,
                isDark: isDark,
                emphasis:
                    overdue
                        ? OperationalMetricEmphasis.alert
                        : OperationalMetricEmphasis.normal,
              ),
              const SizedBox(height: TokensStrip.s4),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  DashboardHomeActionChip(
                    label: 'Editar',
                    accent: primary,
                    isDark: isDark,
                    onPressed: onEdit,
                  ),
                  if (pending) ...[
                    DashboardHomeActionChip(
                      label: 'PIX',
                      accent: primary,
                      isDark: isDark,
                      onPressed: onPix,
                    ),
                    DashboardHomeActionChip(
                      label: 'Cobrar no chat',
                      accent: primary,
                      isDark: isDark,
                      onPressed: onChat,
                    ),
                    DashboardHomeActionChip(
                      label: 'Registrar contato',
                      accent: primary,
                      isDark: isDark,
                      onPressed: onContato,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (pending)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
              ),
              child: FxLiquidPrimaryButton(
                label: 'Marcar como paga',
                loading: paying,
                onPressed: paying ? null : onPay,
              ),
            ),
          ),
      ],
    );
  }
}
