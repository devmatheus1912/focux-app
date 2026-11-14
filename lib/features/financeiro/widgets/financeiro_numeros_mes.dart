import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_numeros.dart';

/// Os três números do mês, no topo do Financeiro: o que entrou, o que falta
/// entrar e o que está atrasado. O mês vem escrito em cima (o "A receber" é só
/// dele; sem isso, uma mensalidade em aberto de outro mês parecia erro). Só o
/// atrasado ganha cor, e só quando existe. Cada um abre a lista que o explica.
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
        Padding(
          padding: const EdgeInsets.only(bottom: TokensStrip.s2),
          child: Text(
            mesPtBr(hoje ?? DateTime.now()),
            style: FocuxHubTypography.rotulo(color: chrome.mute),
          ),
        ),
        FxMetricStrip(
          metricas: [
            FxMetric(
              valor: resumo.totalRecebido.cents,
              texto: resumo.totalRecebido.formatCobranca(),
              rotulo: s.financeiroNumRecebido,
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
        // Recebido e a receber são do mês; o atrasado junta todos os meses.
        if (resumo.totalAtrasado.isPositive)
          Padding(
            padding: const EdgeInsets.only(top: TokensStrip.s2),
            child: Text(
              s.financeiroAtrasadoTodosMeses,
              style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
            ),
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
