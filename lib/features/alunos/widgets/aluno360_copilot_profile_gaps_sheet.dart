import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_copilot_logic.dart';

Future<void> showAluno360CopilotProfileGapsSheet(
  BuildContext context, {
  required Aluno aluno,
  required List<CopilotProfileGap> gaps,
  required Future<void> Function(CopilotProfileGap gap) onSelectGap,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  final ink = fxScreenInk(context);
  final mute = fxScreenMute(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  Future<void> go(CopilotProfileGap gap, BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    await onSelectGap(gap);
  }

  return showFxHomeSheet<void>(
    context,
    builder: (sheetContext) {
      final maxHeight =
          MediaQuery.sizeOf(sheetContext).height *
          FxHomeSheetChrome.maxHeightFactor;
      return FxHomeSheetSurface(
        isDark: isDark,
        maxHeight: maxHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: 'Completar perfil',
              subtitle:
                  gaps.isEmpty
                      ? 'Perfil pronto para decisões da IA.'
                      : '${gaps.length} lacuna(s) afetam a prescrição.',
              leading: Icon(
                Icons.fact_check_outlined,
                color: primary,
                size: 18,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (gaps.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: EagleTokens.good.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: EagleTokens.good.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          'Nada pendente no perfil agora.',
                          style: Aluno360Layout.captionStyle(sheetContext),
                        ),
                      )
                    else
                      ...gaps.map(
                        (gap) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => go(gap, sheetContext),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: fxListCardDecoration(sheetContext),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: BrandPalette.soft(
                                        primary,
                                        dark: isDark,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      gap.icon,
                                      color: primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gap.title,
                                          style: Aluno360Layout.panelTitleStyle(
                                            context,
                                            ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          gap.detail,
                                          style: Aluno360Layout.captionStyle(
                                            context,
                                          ).copyWith(color: mute, height: 1.25),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: mute,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (gaps.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Para ajustes gerais, use Editar nas ações rápidas.',
                          style: Aluno360Layout.captionStyle(
                            sheetContext,
                          ).copyWith(color: mute),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
