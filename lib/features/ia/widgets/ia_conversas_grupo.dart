import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/pt.dart';
import '../data/ia_chat_store.dart';

/// Apaga a conversa (só no aparelho) e mostra "Desfazer", que devolve a
/// conversa ao mesmo lugar (a lista ordena por `atualizadaEm`). Sem
/// confirmação: é dado local, de pouco risco (desvio anotado da rodada 5).
Future<void> apagarConversaComDesfazer(
  BuildContext context,
  WidgetRef ref,
  IaConversa conversa,
) async {
  final store = ref.read(iaChatStoreProvider);
  await store.apagar(conversa.id);
  ref.invalidate(iaConversasProvider);
  if (!context.mounted) return;
  final desfez = await FeedbackHelper.showUndo(context, ptS.iaConversaApagada);
  if (!desfez) return;
  await store.salvar(conversa);
  ref.invalidate(iaConversasProvider);
}

/// Conversas da IA Focux em grupo: tocar abre; arrastar para a esquerda apaga;
/// segurar abre a folha com "Apagar conversa" (atalho, não o único caminho).
class IaConversasGrupo extends ConsumerWidget {
  const IaConversasGrupo({super.key, required this.conversas});

  final List<IaConversa> conversas;

  Future<void> _segurar(BuildContext context, WidgetRef ref, IaConversa c) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: c.titulo,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'apagar',
            rotulo: ptS.iaApagarConversa,
            icone: FxIcons.excluir,
            perigo: true,
          ),
        ]),
      ],
    );
    if (escolha == 'apagar' && context.mounted) {
      await apagarConversaComDesfazer(context, ref, c);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FxSettingsGroup(
      children: [
        for (final (i, c) in conversas.indexed)
          Dismissible(
            key: ValueKey('ia-conversa-${c.id}'),
            direction: DismissDirection.endToStart,
            background: const SizedBox.shrink(),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: EagleTokens.bad.withValues(alpha: 0.12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FxIcons.excluir, color: EagleTokens.bad),
                  const SizedBox(width: 6),
                  Text(
                    ptS.iaApagar,
                    style: FocuxHubTypography.chip(EagleTokens.bad),
                  ),
                ],
              ),
            ),
            onDismissed: (_) => apagarConversaComDesfazer(context, ref, c),
            child: FxSettingsTile(
              icon: FxIcons.chat,
              label: c.titulo,
              subtitle: [
                if (c.alunoNome != null) 'Sobre ${c.alunoNome}',
                dataCurta(c.atualizadaEm),
              ].join(' · '),
              value: '',
              showDivider: i < conversas.length - 1,
              onTap: () => context.push('/ia/chat?c=${c.id}'),
              onLongPress: () => _segurar(context, ref, c),
            ),
          ),
      ],
    );
  }
}
