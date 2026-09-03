import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_hub_display.dart';

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
  String? _erro;

  @override
  void initState() {
    super.initState();
    _mensalidade = widget.initial;
    if (_mensalidade == null) {
      _carregar();
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final loaded = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).buscar(widget.mensalidadeId);
      if (!mounted) return;
      setState(() {
        _mensalidade = loaded;
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final m = _mensalidade;

    return fxScreenA11yScope(
      label:
          m == null
              ? 'Mensalidade'
              : 'Mensalidade de ${m.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: m?.alunoNome ?? 'Mensalidade',
          subtitle:
              m == null
                  ? null
                  : financeiroMensalidadeMesPorExtenso(m.mesReferencia),
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
                : _DetailBody(mensalidade: m, pending: _pending(m)),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.mensalidade, required this.pending});

  final Mensalidade mensalidade;
  final bool pending;

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
              OperationalMetricTile(
                label: status,
                value: formatBrlCurrency(
                  mensalidade.valor,
                  showDecimals: false,
                ),
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
                    onPressed: () => context.pop('edit'),
                  ),
                  if (pending) ...[
                    DashboardHomeActionChip(
                      label: 'PIX',
                      accent: primary,
                      isDark: isDark,
                      onPressed: () => context.pop('pix'),
                    ),
                    DashboardHomeActionChip(
                      label: 'Cobrar no chat',
                      accent: primary,
                      isDark: isDark,
                      onPressed: () => context.pop('chat'),
                    ),
                    DashboardHomeActionChip(
                      label: 'Registrar contato',
                      accent: primary,
                      isDark: isDark,
                      onPressed: () => context.pop('contato'),
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
                onPressed: () => context.pop('pay'),
              ),
            ),
          ),
      ],
    );
  }
}
