import 'package:flutter/material.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../data/alertas_repository.dart';

class AlertasConfigStrip extends StatelessWidget {
  const AlertasConfigStrip({
    super.key,
    required this.config,
    required this.onEditar,
  });

  final AlertasConfiguracao config;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              chrome.isDark
                  ? heroTealSurface(0.04)
                  : brand.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: chrome.isDark ? chrome.line : brand.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: chrome.mute),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Dispara se: ',
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                    TextSpan(
                      text: 'sem treino > ${config.diasSemTreino} dias ',
                      style: FocuxHubTypography.bodyMuted(
                        color: chrome.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: 'ou ',
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                    TextSpan(
                      text: 'aderência < ${config.aderenciaMinima}%',
                      style: FocuxHubTypography.bodyMuted(
                        color: chrome.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onEditar,
              child: Text(
                'Editar',
                style: FocuxHubTypography.chip(brand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
