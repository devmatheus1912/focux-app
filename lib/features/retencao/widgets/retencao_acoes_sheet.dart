import 'package:flutter/material.dart';

import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../data/retencao_repository.dart';

enum RetencaoAcao { mensagem, perfil, ficha, cobrar, adiar }

/// Ações do aluno, com os motivos completos no topo.
Future<RetencaoAcao?> showRetencaoAcoesSheet(
  BuildContext context, {
  required RetencaoAlunoScore score,
}) {
  final s = S.of(context);
  return showFxGroupedActionSheet<RetencaoAcao>(
    context,
    titulo: score.alunoNome,
    subtitulo: score.motivos.isEmpty ? null : score.motivos.join(' · '),
    grupos: [
      FxActionGroup<RetencaoAcao>(null, [
        FxActionItem(
          valor: RetencaoAcao.mensagem,
          rotulo: s.retencaoAcaoMensagem,
          icone: Icons.chat_bubble_outline_rounded,
        ),
        FxActionItem(
          valor: RetencaoAcao.perfil,
          rotulo: s.retencaoAcaoPerfil,
          icone: Icons.person_outline_rounded,
        ),
        if (score.semFicha)
          FxActionItem(
            valor: RetencaoAcao.ficha,
            rotulo: s.retencaoAcaoFicha,
            icone: Icons.fitness_center_rounded,
          ),
        if (score.cobravel)
          FxActionItem(
            valor: RetencaoAcao.cobrar,
            rotulo: s.retencaoAcaoCobrar,
            icone: Icons.payments_outlined,
          ),
        if (!score.adiado)
          FxActionItem(
            valor: RetencaoAcao.adiar,
            rotulo: s.retencaoAcaoAdiar,
            icone: Icons.snooze_rounded,
          ),
      ]),
    ],
  );
}
