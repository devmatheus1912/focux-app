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
    this.isToday = false,
    this.width = 52,
  });

  final String weekdayLabel;
  final int dayNumber;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final bool isToday;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final fill = chrome.cardFill;
    final todayHint = isToday && !selected;

    return Semantics(
      button: true,
      selected: selected,
      label: [
        '$weekdayLabel $dayNumber',
        if (isToday) 'hoje',
        if (count > 0) '$count atendimento${count == 1 ? '' : 's'}',
      ].join(', '),
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
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
                      ],
                    ),
                  ),
                  if (todayHint)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  if (count > 0)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: FocuxHubTypography.chip(Colors.white).copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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
