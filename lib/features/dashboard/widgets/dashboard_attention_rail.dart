import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_attention_card.dart';
import 'dashboard_collapsible_section.dart';
import 'dashboard_horizontal_scroll_peek.dart';

/// Rail colapsável “Precisa de atenção” (risco + vencimentos).
class DashboardAttentionRail extends StatelessWidget {
  const DashboardAttentionRail({
    super.key,
    required this.isDark,
    required this.riskDominante,
    required this.riscoAlto,
    required this.alunosAtivos,
    required this.dayFocusCoversRetention,
    required this.collapseAttention,
    required this.attentionRiskItems,
    required this.attentionVencItems,
    required this.attentionCollapsedPreview,
    required this.resetToken,
    required this.onReview,
  });

  final bool isDark;
  final bool riskDominante;
  final int riscoAlto;
  final int alunosAtivos;
  final bool dayFocusCoversRetention;
  final bool collapseAttention;
  final List<Aluno> attentionRiskItems;
  final List<VencimentoItem> attentionVencItems;
  final String? attentionCollapsedPreview;
  final int resetToken;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final attentionItemCount =
        attentionRiskItems.length + attentionVencItems.length;
    final compact = DashboardLayout.isCompact(MediaQuery.sizeOf(context).width);
    final cardWidth =
        compact
            ? DashboardLayout.attentionCardWidthCompact
            : DashboardLayout.attentionCardWidth;

    return DashboardCollapsibleSection(
      title: DashboardMicrocopy.precisaDeAtencao,
      collapsedHint:
          attentionRiskItems.isEmpty && attentionVencItems.isNotEmpty
              ? '${attentionVencItems.length} vencimento${attentionVencItems.length == 1 ? '' : 's'} pendente${attentionVencItems.length == 1 ? '' : 's'} · Revisar'
              : riskDominante
              ? '$riscoAlto de $alunosAtivos · Revisar'
              : riscoAlto > 0
              ? '$riscoAlto no radar · Revisar'
              : 'Cobranças pendentes · Revisar',
      collapsedActionLabel: 'Revisar',
      onCollapsedAction: onReview,
      collapsedPreview: attentionCollapsedPreview,
      isDark: isDark,
      initiallyExpanded: !collapseAttention,
      resetToken: resetToken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!dayFocusCoversRetention)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/retencao'),
                child: const Text('Saúde da base'),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  () => goPersonalShellTab(context, '/alunos?filtro=risco'),
              child: Text(
                riscoAlto > 1 ? 'Ver tudo · +${riscoAlto - 1}' : 'Ver tudo',
              ),
            ),
          ),
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: dashboardAttentionCarouselSemantics(attentionItemCount),
            child: DashboardHorizontalScrollPeek(
              showPeek: attentionItemCount > 1,
              child: SizedBox(
                height: DashboardLayout.attentionRailHeight,
                child: ListView.separated(
                  // ignore: deprecated_member_use
                  cacheExtent: 280,
                  key: const PageStorageKey('personal-attention-rail'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensStrip.s4,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: attentionItemCount,
                  separatorBuilder:
                      (_, __) => SizedBox(width: TokensStrip.s3),
                  itemBuilder: (context, index) {
                    if (index < attentionRiskItems.length) {
                      final aluno = attentionRiskItems[index];
                      return SizedBox(
                        width: cardWidth,
                        child: RepaintBoundary(
                          child: DashboardAttentionCard(
                            listIndex: index + 1,
                            listTotal: attentionItemCount,
                            nome: aluno.nome,
                            objetivo: aluno.objetivo,
                            titulo: attentionSignalLabel(aluno),
                            subt: attentionSignalSub(aluno),
                            acao: 'Revisar',
                            isDark: isDark,
                            showStatusBadge:
                                !riskDominante ||
                                aluno.inadimplente ||
                                aluno.statusFinanceiro == 'INADIMPLENTE',
                            statusAccent: EagleTokens.warn,
                            onTap: () => context.push('/alunos/${aluno.id}'),
                          ),
                        ),
                      );
                    }
                    final v =
                        attentionVencItems[index - attentionRiskItems.length];
                    return SizedBox(
                      width: cardWidth,
                      child: RepaintBoundary(
                        child: DashboardAttentionCard(
                          listIndex: index + 1,
                          listTotal: attentionItemCount,
                          nome: v.alunoNome,
                          titulo: 'Inadimplente',
                          subt: 'R\$ ${v.valor.toStringAsFixed(0)} pendente',
                          acao: 'Cobrar',
                          isDark: isDark,
                          onTap: () => context.go('/financeiro'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
