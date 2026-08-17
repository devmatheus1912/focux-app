import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../data/alertas_repository.dart';

class AlertaRiscoCard extends StatelessWidget {
  const AlertaRiscoCard({
    super.key,
    required this.alerta,
    required this.onMensagem,
    required this.onResolver,
  });

  final AlertaRisco alerta;
  final VoidCallback onMensagem;
  final VoidCallback onResolver;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = Theme.of(context).colorScheme.primary;
    final brandDeep = BrandPalette.deep(brand);
    final sColor = _scoreColor(alerta.score, chrome.isDark);
    final sBg = _scoreBg(alerta.score, chrome.isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: fxListCardDecoration(
        context,
        accent: alerta.score >= 2 ? EagleTokens.bad : null,
        radius: 20,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: chrome.isDark ? brandDeep : brand,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    fxInitials(alerta.alunoNome),
                    style: TextStyle(
                      color: heroTealInk(),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              alerta.alunoNome,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: chrome.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: sBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Score ${alerta.score}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...alerta.motivos.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: sColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: sColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${alerta.diasSemTreino ?? 0}d',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: sColor,
                      ),
                    ),
                    Text(
                      '${alerta.aderenciaPercent?.toStringAsFixed(0) ?? 0}% ader.',
                      style: TextStyle(fontSize: 10.5, color: chrome.mute),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: chrome.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onMensagem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: chrome.line)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '💬 Mensagem',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: brand,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: onResolver,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: Text(
                        '✓ Resolvido',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              chrome.isDark
                                  ? const Color(0xFF6FE296)
                                  : EagleTokens.good,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int s, bool isDark) =>
      s >= 2
          ? EagleTokens.semanticBad(isDark: isDark)
          : EagleTokens.semanticWarn(isDark: isDark);

  Color _scoreBg(int s, bool isDark) =>
      s >= 2
          ? EagleTokens.semanticBadSoft(isDark: isDark)
          : EagleTokens.semanticWarnSoft(isDark: isDark);
}
