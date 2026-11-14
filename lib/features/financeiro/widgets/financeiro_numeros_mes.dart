import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_numeros.dart';

/// Os três números do topo do Financeiro: o que entrou no mês ("Recebido em
/// nov"), o que ainda vai entrar e o que está atrasado (esses dois de todos os
/// meses, iguais às listas que abrem). Só o atrasado ganha cor, e só quando
/// existe. Cada um abre a lista que o explica.
class FinanceiroNumerosMes extends StatelessWidget {
  const FinanceiroNumerosMes({
    super.key,
    required this.resumo,
    required this.onAbrir,
    this.hoje,
  });

  final ResumoMensal resumo;
  final ValueChanged<MensalidadeFiltro> onAbrir;

  /// O mês do resumo (o servidor manda o mês corrente); nulo = agora.
  final DateTime? hoje;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final nota = financeiroNotaDoRecebido(s, resumo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FxMetricStrip(
          metricas: [
            FxMetric(
              valor: resumo.totalRecebido.cents,
              texto: resumo.totalRecebido.formatCobranca(),
              rotulo: financeiroRotuloRecebido(s, hoje ?? DateTime.now()),
              onTap: () => onAbrir(MensalidadeFiltro.pagas),
            ),
            FxMetric(
              valor: resumo.totalEmAberto.cents,
              texto: resumo.totalEmAberto.formatCobranca(),
              rotulo: s.financeiroNumAReceber,
              onTap: () => onAbrir(MensalidadeFiltro.abertas),
            ),
            FxMetric(
              valor: resumo.totalAtrasado.cents,
              texto: resumo.totalAtrasado.formatCobranca(),
              rotulo: s.financeiroNumAtrasado,
              alerta: true,
              onTap: () => onAbrir(MensalidadeFiltro.atrasadas),
            ),
          ],
        ),
        if (nota != null)
          Padding(
            padding: const EdgeInsets.only(top: TokensStrip.s2),
            child: Text(
              nota,
              style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
            ),
          ),
      ],
    );
  }
}
