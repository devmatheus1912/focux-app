import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../l10n/app_localizations.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../planos/utils/plan_gate.dart';
import '../../ia/widgets/ia_uso_linha.dart';
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

/// O que vimos, o que fazer e uma ação. Gerar com IA fica à parte e diz o custo.
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

  /// Gerar custa um uso de IA: fica à parte, com a conta do mês à vista.
  void _abrirGerarIa(BuildContext context) {
    showFxHomeSheet<void>(
      context,
      builder: (_) => _GerarComIaFolha(aluno: aluno),
    );
  }

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

    Widget titulo(String t) => Text(
      t,
      style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
    );

    return FxSheetFrame(
      title: s.alunoResumoCopilotoTitulo,
      subtitle: aluno.nome,
      leading: Icon(Icons.auto_awesome_outlined, color: primary, size: 20),
      footer: Padding(
        padding: const EdgeInsets.all(TokensStrip.s3),
        child: FxLiquidPrimaryButton(
          label: tarefaCriada ? s.copilotoFolhaTarefaCriada : snapshot.stickyAction.label,
          onPressed:
              tarefaCriada
                  ? null
                  : () {
                    Navigator.of(context).pop();
                    abrirOperacaoSticky(
                      context: context,
                      aluno: aluno,
                      alunoId: aluno.id,
                      sticky: snapshot.stickyAction,
                      proxima: proxima,
                      outreach: snapshot.outreachMessage,
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
            if (fatos.isNotEmpty) ...[
              titulo(s.copilotoFolhaOQueVimos),
              const SizedBox(height: TokensStrip.s2),
              for (final fato in fatos)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensStrip.s1),
                  child: Text(
                    fato,
                    style: FocuxHubTypography.body(color: chrome.ink),
                  ),
                ),
              const SizedBox(height: TokensStrip.s3),
            ],
            Row(
              children: [
                Expanded(child: titulo(s.copilotoFolhaOQueFazer)),
                if (ia != null)
                  FxStatusPill(
                    label: s.copilotoFolhaSeloIa,
                    tone: FxPillTone.accent,
                  ),
                IconButton(
                  tooltip: s.copilotoFolhaMaisOpcoes,
                  icon: Icon(Icons.more_horiz_rounded, color: chrome.mute),
                  onPressed: () => _abrirGerarIa(context),
                ),
              ],
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(texto, style: FocuxHubTypography.body(color: chrome.ink)),
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
