import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (sheetContext) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              16 + MediaQuery.of(sheetContext).padding.bottom,
            ),
            child: ShellSurface(
              radius: TokensStrip.rCard,
              accent: primary,
              padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completar perfil',
                              style: TextStyle(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              gaps.isEmpty
                                  ? 'Perfil pronto para decisões da IA.'
                                  : '${gaps.length} lacuna(s) afetam a prescrição.',
                              style: TextStyle(color: mute, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
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
                      child: const Text('Nada pendente no perfil agora.'),
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
                                        style: TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        gap.detail,
                                        style: TextStyle(
                                          color: mute,
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: mute),
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
                        style: TextStyle(color: mute, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
  );
}
