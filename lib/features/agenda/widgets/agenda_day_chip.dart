import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';

class AgendaDayChip extends StatelessWidget {
  const AgendaDayChip({
    super.key,
    required this.weekdayLabel,
    required this.dayNumber,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.width = 52,
  });

  final String weekdayLabel;
  final int dayNumber;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final double width;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final fill = chrome.cardFill;

    return Semantics(
      button: true,
      selected: selected,
      label:
          count > 0
              ? '$weekdayLabel $dayNumber, $count atendimento${count == 1 ? '' : 's'}'
              : '$weekdayLabel $dayNumber',
      child: Material(
        color: fxTransparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            width: width,
            decoration: BoxDecoration(
              color:
                  selected
                      ? BrandPalette.soft(primary, dark: chrome.isDark)
                      : fill,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(
                color:
                    selected
                        ? primary.withValues(alpha: 0.42)
                        : chrome.lineStrong,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FxHomeSheetChrome.touchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayLabel,
                      style: FocuxHubTypography.bodyMuted(
                        color: selected ? primary : chrome.mute,
                        fontWeight: FontWeight.w700,
                      ).copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dayNumber',
                      style: FocuxHubTypography.cardTitle(
                        color: selected ? primary : chrome.ink,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: FocuxHubTypography.chip(Colors.white).copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
