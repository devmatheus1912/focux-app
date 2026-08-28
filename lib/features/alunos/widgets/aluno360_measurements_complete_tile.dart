import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Estado de sucesso quando todas as medidas corporais estão completas.
class Aluno360MeasurementsCompleteTile extends StatelessWidget {
  const Aluno360MeasurementsCompleteTile({
    super.key,
    required this.summary,
    required this.primary,
    required this.onTap,
  });

  final String summary;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);
    final accent = BrandPalette.deep(primary);
    final bg = primary.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.08,
    );

    return Semantics(
      button: true,
      label: 'Medidas em dia. $summary. Toque para ver evolução.',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.verified_outlined,
                  size: 22,
                  color: accent,
                ),
              ),
              const SizedBox(width: FxSettingsLayout.iconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medidas em dia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FxSettingsLayout.rowLabel(color: ink),
                    ),
                    const SizedBox(height: FxSettingsLayout.captionAfterHeader),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FxSettingsLayout.subhead(color: mute),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TokensStrip.s1),
              Icon(
                Icons.chevron_right,
                size: FxSettingsLayout.chevronSize,
                color: mute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
