import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_hub_display.dart';

class FinanceiroMensalidadeDetailScreen extends StatelessWidget {
  const FinanceiroMensalidadeDetailScreen({
    super.key,
    required this.mensalidade,
  });

  final Mensalidade mensalidade;

  bool get _pending =>
      mensalidade.status == 'PENDENTE' || mensalidade.status == 'ATRASADO';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final overdue = mensalidade.status == 'ATRASADO';
    final statusColor = overdue ? EagleTokens.bad : primary;
    final mes = financeiroMensalidadeMesPorExtenso(mensalidade.mesReferencia);
    final status = financeiroMensalidadeStatusLabel(mensalidade.status);

    return fxScreenA11yScope(
      label: 'Mensalidade de ${mensalidade.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: mensalidade.alunoNome,
          subtitle: mes,
        ),
        body: Column(
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
                      if (_pending) ...[
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
            if (_pending)
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
        ),
      ),
    );
  }
}
