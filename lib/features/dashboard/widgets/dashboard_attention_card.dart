import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_readability.dart';

class DashboardAttentionCard extends StatelessWidget {
  const DashboardAttentionCard({
    super.key,
    required this.nome,
    required this.titulo,
    required this.subt,
    required this.acao,
    required this.isDark,
    this.objetivo,
    this.showStatusBadge = true,
    this.statusAccent,
    this.onTap,
    this.listIndex,
    this.listTotal,
  });

  final String nome;
  final String titulo;
  final String subt;
  final String acao;
  final String? objetivo;
  final bool isDark;
  final bool showStatusBadge;
  final Color? statusAccent;
  final VoidCallback? onTap;
  final int? listIndex;
  final int? listTotal;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final accent = statusAccent ?? EagleTokens.warn;

    final semanticsLabel =
        listIndex != null && listTotal != null
            ? dashboardAttentionItemSemantics(
              index: listIndex!,
              total: listTotal!,
              nome: nome,
              titulo: titulo,
              subt: subt,
              acao: acao,
            )
            : '$nome, $titulo. $subt. Toque para $acao';

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Tooltip(
        message:
            objetivo?.trim().isNotEmpty == true
                ? '${fxTitleCaseName(nome)} · ${objetivo!.trim()}'
                : fxTitleCaseName(nome),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Container(
            width: DashboardLayout.attentionCardWidth,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: fxStripCardDecoration(
              context,
              accent: primary,
              radius: TokensStrip.rCard,
              glowStrength: 0.1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: primary,
                      child: Text(
                        fxInitials(nome),
                        style: AppTypography.inter(
                          color: Colors.white,
                          fontSize: TokensStrip.fontBodySm,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fxTitleCaseName(nome),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: dashboardCardTitleStyle(
                              ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            objetivo?.trim().isNotEmpty == true
                                ? objetivo!.trim()
                                : 'Objetivo não definido',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (showStatusBadge) ...[
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          titulo.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dashboardMicroLabelStyle(
                            context,
                            isDark: isDark,
                            color: accent,
                            letterSpacing: 0.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  showStatusBadge ? subt : titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: dashboardCardSubtitleStyle(
                    context,
                    isDark: isDark,
                    fontWeight:
                        showStatusBadge ? FontWeight.w400 : FontWeight.w600,
                  ).copyWith(color: ink),
                ),
                if (!showStatusBadge) ...[
                  const SizedBox(height: 4),
                  Text(
                    subt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: dashboardCardSubtitleStyle(context, isDark: isDark),
                  ),
                ],
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: primarySoft,
                    borderRadius: BorderRadius.circular(TokensStrip.rInput),
                    border: Border.all(
                      color: primary.withValues(alpha: isDark ? 0.45 : 0.28),
                    ),
                    boxShadow: TokensStrip.coloredDepthGlow(
                      primary,
                      strength: 0.1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    acao,
                    style: AppTypography.inter(
                      fontSize: TokensStrip.fontBodySm,
                      fontWeight: FontWeight.w700,
                      color: BrandPalette.sectionAction(primary, dark: isDark),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
