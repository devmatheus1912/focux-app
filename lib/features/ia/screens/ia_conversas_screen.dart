import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../data/ia_chat_store.dart';
import '../widgets/ia_conversas_grupo.dart';

/// Todas as conversas da IA Focux guardadas no aparelho (até 20), mais recente
/// primeiro. Arrastar ou segurar apaga; "Apagar todas" fica no "⋯", com
/// confirmação. Vazia, volta para a abertura da IA.
class IaConversasScreen extends ConsumerWidget {
  const IaConversasScreen({super.key});

  Future<void> _maisAcoes(BuildContext context, WidgetRef ref, int total) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.iaConversasTitulo,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'todas',
            rotulo: ptS.iaApagarTodas,
            icone: FxIcons.excluir,
            perigo: true,
          ),
        ]),
      ],
    );
    if (escolha != 'todas' || !context.mounted) return;
    final ok = await showFxConfirmSheet(
      context,
      title: ptS.iaApagarTodasTitulo(total),
      message: ptS.iaApagarTodasTexto,
      icon: FxIcons.excluir,
      confirmLabel: ptS.iaApagarTodas,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(iaChatStoreProvider).apagarTodas();
    ref.invalidate(iaConversasProvider);
    if (context.mounted) safePopOrGo(context, '/ia/copiloto');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversas = ref.watch(iaConversasProvider).value ?? const [];
    if (ref.watch(iaConversasProvider).hasValue && conversas.isEmpty) {
      // A última foi apagada: a lista vazia volta para a abertura da IA.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) safePopOrGo(context, '/ia/copiloto');
      });
    }
    return fxScreenA11yScope(
      label: ptS.iaConversasTitulo,
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: ptS.iaConversasTitulo,
          onBack: () => safePopOrGo(context, '/ia/copiloto'),
          actions: [
            if (conversas.isNotEmpty)
              IconButton(
                tooltip: ptS.iaMaisAcoes,
                icon: const Icon(FxIcons.mais),
                onPressed: () => _maisAcoes(context, ref, conversas.length),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            FxSettingsLayout.headerToGroup,
            FxSettingsLayout.pageInset,
            96,
          ),
          children: [
            if (conversas.isNotEmpty) IaConversasGrupo(conversas: conversas),
          ],
        ),
      ),
    );
  }
}
