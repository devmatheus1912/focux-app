import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Faixa compacta de ativação no fold da Home — linha 52 + barra no fio inferior.
/// Não compete com o cumprimento: fica *abaixo* do Olá, no ritmo do Perfil.
class DashboardHomeActivationStrip extends StatelessWidget {
  const DashboardHomeActivationStrip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.progress,
    this.trailingMetric,
    this.semanticsLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double? progress;
  final String? trailingMetric;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final metric = trailingMetric;
    final bar = progress;
    final label =
        semanticsLabel ??
        (metric == null ? '$title. $subtitle' : '$title, $metric. $subtitle');

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          child: Ink(
            decoration: fxStripCardDecoration(
              context,
              accent: brand,
              radius: FxSettingsLayout.groupRadius,
              glowStrength: 0.04,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      TokensStrip.s2,
                      TokensStrip.s3,
                      bar != null ? TokensStrip.s2 : TokensStrip.s2,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: FxSettingsLayout.rowMinHeight,
                      ),
                      child: Row(
                        children: [
                          FxIcon(
                            name: 'spark',
                            size: FxSettingsLayout.iconSize,
                            color: brand,
                          ),
                          const SizedBox(width: FxSettingsLayout.iconGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.cardTitle(
                                    color: chrome.ink,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FocuxHubTypography.bodyMuted(
                                      color: chrome.mute,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (metric != null && metric.isNotEmpty) ...[
                            const SizedBox(width: TokensStrip.s2),
                            Text(
                              metric,
                              style: FocuxHubTypography.metric(
                                color: brand,
                                fontSize: TokensStrip.fontBodySm,
                              ),
                            ),
                            const SizedBox(width: TokensStrip.s1),
                          ],
                          Icon(
                            Icons.chevron_right,
                            size: FxSettingsLayout.chevronSize,
                            color: chrome.mute,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (bar != null)
                    LinearProgressIndicator(
                      value: bar.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: brand.withValues(alpha: 0.12),
                      color: brand,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
