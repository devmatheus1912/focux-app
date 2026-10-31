import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../ia/widgets/ia_uso_linha.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../planos/utils/plan_gate.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_copilot_logic.dart';
import '../utils/aluno360_operacao_logic.dart';
import 'aluno360_acao_sticky.dart';
import 'aluno360_copilot_ia_refresh_button.dart';

Future<void> showAluno360CopilotFolha(
  BuildContext context, {
  required Aluno aluno,
  required Aluno360OperacaoSnapshot snapshot,
  required String acao,
  required String? motivo,
  required ProximaAcaoResumo? proxima,
  required bool tarefaCriada,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (_) => _CopilotFolha(
          aluno: aluno,
          snapshot: snapshot,
          acao: acao,
          motivo: motivo,
          proxima: proxima,
          tarefaCriada: tarefaCriada,
        ),
  );
}

/// O que fazer em destaque, o porquê em linhas e uma ação que combina com a
/// sugestão. Gerar com IA fica no "⋯" e diz o custo.
class _CopilotFolha extends ConsumerWidget {
  const _CopilotFolha({
    required this.aluno,
    required this.snapshot,
    required this.acao,
    required this.motivo,
    required this.proxima,
    required this.tarefaCriada,
  });

  final Aluno aluno;
  final Aluno360OperacaoSnapshot snapshot;
  final String acao;
  final String? motivo;
  final ProximaAcaoResumo? proxima;
  final bool tarefaCriada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final iaLiberada = PlanGate.watch(ref, PlanoRecursoKeys.ia).liberado;
    final forcada =
        iaLiberada && ref.watch(alunoCopilotoForceIaProvider(aluno.id));
    final ia =
        forcada ? ref.watch(alunoCopilotoActionProvider(aluno.id)).value : null;
    final texto =
        ia?.rawAcaoOrFallback.trim().isNotEmpty == true
            ? ia!.rawAcaoOrFallback.trim()
            : acao;
    final fatos = copilotoFatos(aluno, motivo: ia?.motivo ?? motivo);
    final tipo = ia?.tipoAcao ?? proxima?.tipoAcao;
    final acaoPrincipal = copilotoAcaoDaSugestao(
      tipo,
      padrao: snapshot.stickyAction,
    );
    final mensagem =
        (ia?.mensagemSugerida ?? proxima?.mensagemSugerida ?? '').trim();
    final outreach = mensagem.isEmpty ? snapshot.outreachMessage : mensagem;

    Widget rotulo(String t) =>
        Text(t, style: FocuxHubTypography.chip(chrome.mute));

    return FxSheetFrame(
      title: s.alunoResumoCopilotoTitulo,
      subtitle: aluno.nome,
      leading: Icon(Icons.auto_awesome_outlined, color: primary, size: 20),
      footer: Padding(
        padding: const EdgeInsets.all(TokensStrip.s3),
        child: FxLiquidPrimaryButton(
          label:
              tarefaCriada ? s.copilotoFolhaTarefaCriada : acaoPrincipal.label,
          onPressed:
              tarefaCriada
                  ? null
                  : () {
                    Navigator.of(context).pop();
                    abrirOperacaoSticky(
                      context: context,
                      aluno: aluno,
                      alunoId: aluno.id,
                      sticky: acaoPrincipal,
                      proxima: proxima,
                      outreach: outreach,
                    );
                  },
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s3,
          0,
          TokensStrip.s3,
          TokensStrip.s3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: rotulo(s.copilotoFolhaOQueFazer)),
                if (ia != null)
                  FxStatusPill(
                    label: s.copilotoFolhaSeloIa,
                    tone: FxPillTone.accent,
                  ),
                IconButton(
                  tooltip: s.copilotoFolhaMaisOpcoes,
                  icon: Icon(Icons.more_horiz_rounded, color: chrome.mute),
                  onPressed:
                      () => showFxHomeSheet<void>(
                        context,
                        builder: (_) => _GerarComIaFolha(aluno: aluno),
                      ),
                ),
              ],
            ),
            Text(
              texto,
              style: FocuxHubTypography.cardTitle(
                color: chrome.ink,
              ).copyWith(fontSize: 18, height: 1.3),
            ),
            if (fatos.isNotEmpty) ...[
              const SizedBox(height: TokensStrip.s4),
              rotulo(s.copilotoPorQue),
              const SizedBox(height: TokensStrip.s2),
              for (final fato in fatos)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: primary,
                      ),
                      const SizedBox(width: TokensStrip.s2),
                      Expanded(
                        child: Text(
                          fato,
                          style: FocuxHubTypography.body(color: chrome.ink),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (acaoPrincipal.isChatAction && outreach.trim().isNotEmpty) ...[
              const SizedBox(height: TokensStrip.s3),
              rotulo(s.copilotoMensagemPronta),
              const SizedBox(height: TokensStrip.s2),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outreach,
                        style: FocuxHubTypography.body(color: chrome.ink),
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      FxTonalButton(
                        label: s.copilotoCopiar,
                        icon: Icons.copy_rounded,
                        compact: true,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: outreach),
                          );
                          if (context.mounted) {
                            FeedbackHelper.showSuccess(
                              context,
                              s.copilotoCopiado,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GerarComIaFolha extends ConsumerWidget {
  const _GerarComIaFolha({required this.aluno});

  final Aluno aluno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final plano = ref.watch(planoFeaturesProvider).value;
    final limite = plano?.limiteIaMensal ?? 0;
    return FxSheetFrame(
      title: s.copilotoFolhaGerarIa,
      subtitle: s.copilotoFolhaGerarIaCusto,
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (limite > 0) ...[
              IaUsoLinha(usado: plano!.iaUsadaMes, limite: limite),
              const SizedBox(height: TokensStrip.s3),
            ],
            Aluno360CopilotIaRefreshButton(
              alunoId: aluno.id,
              primary: Theme.of(context).colorScheme.primary,
              prominent: true,
            ),
          ],
        ),
      ),
    );
  }
}
