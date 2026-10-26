import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../../health/data/health_repository.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../data/aluno_followup_store.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import '../utils/aluno360_resumo_agora.dart';
import 'aluno360_copilot_card.dart';
import 'aluno360_ficha_card.dart';
import 'aluno360_follow_up_card.dart';
import 'aluno360_acao_sticky.dart';
import 'aluno360_recovery_insight_card.dart';

/// Aba Resumo do perfil 360: o que fazer agora, os números, a ficha, o
/// dinheiro, o próximo contato e a sugestão do copiloto. Sem folha para o
/// básico; só a sugestão do copiloto abre uma.
class Aluno360ResumoTab extends ConsumerWidget {
  const Aluno360ResumoTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.proximaAcao360,
    required this.hasOpenCopilotTask360,
    required this.aderenciaSemanal,
    this.aderenciaBundle,
    required this.recoveryAsync,
    required this.autonomiaResumoAsync,
    this.riscoMotivo,
    this.hoje,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final Color primary;
  final ProximaAcaoResumo? proximaAcao360;
  final bool hasOpenCopilotTask360;
  final List<Map<String, dynamic>>? aderenciaSemanal;
  final AderenciaSemanalBundle? aderenciaBundle;
  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final AsyncValue<AlunoAutonomiaResumo> autonomiaResumoAsync;

  /// Primeiro motivo de risco que o servidor mandou (texto livre).
  final String? riscoMotivo;

  /// Para teste (golden estável); por padrão, agora.
  final DateTime? hoje;

  void _abrirCopiloto(BuildContext context) {
    showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final escuro = Theme.of(ctx).brightness == Brightness.dark;
        return FxHomeSheetSurface(
          isDark: escuro,
          child: ListView(
            shrinkWrap: true,
            children: [
              FxHomeSheetHandle(isDark: escuro),
              const SizedBox(height: TokensStrip.s4),
              Aluno360CopilotCard(
                aluno: aluno,
                alunoId: alunoId,
                resumoAsync: autonomiaResumoAsync,
                proximaAcao360: proximaAcao360,
                hasOpenCopilotTask360: hasOpenCopilotTask360,
                isDark: escuro,
              ),
            ],
          ),
        );
      },
    );
  }

  List<FxMetric> _metricas(
    BuildContext context,
    S s,
    int checkins,
    VoidCallback abrirEngajamento,
  ) {
    final ader = aluno.aderenciaPercent ?? 0;
    final dias = aluno.diasSemTreino ?? 0;
    return [
      FxMetric(
        valor: ader,
        rotulo: s.alunoResumoMetricaAderencia,
        alerta: ader > 0 && ader < 50,
        onTap: abrirEngajamento,
      ),
      FxMetric(
        valor: dias,
        rotulo: s.alunoResumoMetricaDiasSemTreino,
        alerta: dias >= AlunoFollowUpStore.diasSemTreinoLimite,
        onTap: abrirEngajamento,
      ),
      FxMetric(
        valor: checkins,
        rotulo: s.alunoResumoMetricaCheckins,
        onTap: abrirEngajamento,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final snapshot = ref.watch(aluno360OperacaoProvider(alunoId));
    final financeiroEmAtraso =
        aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente;
    final contactPriority = snapshot?.contactPriority ?? false;
    final agora = snapshot == null
        ? null
        : resumoAgora(
            s,
            sticky: snapshot.stickyAction,
            proxima: snapshot.effectiveProxima,
            aluno: aluno,
            contactPriority: contactPriority,
            riscoMotivo: riscoMotivo,
          );
    final acaoCopiloto = snapshot?.effectiveProxima?.acao.trim() ?? '';
    final mostraCopiloto =
        acaoCopiloto.isNotEmpty && acaoCopiloto != agora?.motivo;
    final week = summarizeAderenciaWeek(
      parseAderenciaSemanal(aderenciaSemanal),
      bundle: aderenciaBundle,
    );
    final checkins = week.totalCheckins.round();
    final semTreinos = semHistoricoDeTreino(aluno) && checkins == 0;
    final temRecuperacao = alunoTemHistoricoWearable(recoveryAsync.value);
    void abrirEngajamento() => context.push(
      '/alunos/$alunoId/engajamento',
      extra: aluno.nome,
    );

    final blocos = <Widget>[
      if (snapshot != null) _agora(context, s, chrome, snapshot, agora),
      if (semTreinos)
        Text(
          s.alunoResumoSemTreinosAinda,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        )
      else
        FxMetricStrip(metricas: _metricas(context, s, checkins, abrirEngajamento)),
      Aluno360FichaCard(
        alunoId: alunoId,
        alunoNome: aluno.nome,
        hoje: hoje,
      ),
      if (financeiroEmAtraso &&
          snapshot?.stickyAction.destination !=
              OperacaoStickyDestination.financeiro)
        FxActionRow(
          leading: Icons.payments_outlined,
          titulo: s.alunoResumoFinanceiroTitulo,
          motivo: s.alunoResumoFinanceiroMotivo,
          verbo: s.alunoResumoVerboCobrar,
          onTap: () => context.push('/financeiro?alunoId=$alunoId'),
        ),
      Aluno360FollowUpCard(aluno: aluno),
      if (mostraCopiloto)
        FxActionRow(
          leading: Icons.auto_awesome_outlined,
          titulo: s.alunoResumoCopilotoTitulo,
          motivo: acaoCopiloto,
          verbo: s.alunoResumoCopilotoVerbo,
          onTap: () => _abrirCopiloto(context),
        ),
      if (temRecuperacao)
        Aluno360RecoveryInsightCard(
          recoveryAsync: recoveryAsync,
          isDark: isDark,
          primary: primary,
        ),
    ];

    return Semantics(
      container: true,
      label: 'Conteúdo da aba resumo',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, bloco) in blocos.indexed) ...[
              if (i > 0) const SizedBox(height: Aluno360Layout.sectionGap),
              bloco,
            ],
          ],
        ),
      ),
    );
  }

  Widget _agora(
    BuildContext context,
    S s,
    ShellPalette chrome,
    Aluno360OperacaoSnapshot snapshot,
    ResumoAgora? agora,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.alunoResumoAgoraTitulo,
          style: FocuxHubTypography.eyebrow(context, color: chrome.mute),
        ),
        const SizedBox(height: TokensStrip.s2),
        if (agora == null)
          Text(
            s.alunoResumoNadaUrgente,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          )
        else
          FxActionRow(
            key: const ValueKey('aluno360_resumo_agora'),
            leading: snapshot.stickyAction.icon,
            titulo: agora.titulo,
            motivo: agora.motivo,
            verbo: agoraVerboTexto(s, agora.verbo),
            onTap: () => abrirOperacaoSticky(
              context: context,
              aluno: aluno,
              alunoId: alunoId,
              sticky: snapshot.stickyAction,
              proxima: snapshot.effectiveProxima,
              outreach: snapshot.outreachMessage,
            ),
          ),
      ],
    );
  }
}
