import 'package:flutter/material.dart';

import '../../../../core/widgets/fx_empty_state.dart';
import '../../../../core/widgets/fx_help.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../data/broadcast_repository.dart';
import '../../utils/broadcast_display.dart';

class BroadcastHistorico extends StatelessWidget {
  const BroadcastHistorico({super.key, required this.itens});

  final List<Broadcast> itens;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) {
      return FxEmptyState(
        icon: 'message-circle',
        title: broadcastEmptyTitle(),
        subtitle: broadcastEmptySubtitle(),
      );
    }
    return FxSettingsGroup(
      header: broadcastHistoricoHeader(),
      caption: broadcastEnviosCaption(itens.length),
      children: [
        for (var i = 0; i < itens.length; i++)
          FxSettingsTile(
            fxIcon: broadcastPublicoFxIcon(
              itens[i].tipoConsultoriaAlvo ?? 'TODOS',
            ),
            label: itens[i].titulo,
            subtitle: broadcastTileSubtitle(
              itens[i].mensagem,
              itens[i].enviadoEm,
            ),
            value: broadcastAlunosValue(itens[i].totalEnviados),
            showDivider: i != itens.length - 1,
            onTap: () => _abrir(context, itens[i]),
          ),
      ],
    );
  }

  void _abrir(BuildContext context, Broadcast item) {
    showFxHelpSheet(
      context,
      title: item.titulo,
      subtitle:
          '${broadcastPublicoLabel(item.tipoConsultoriaAlvo)} · ${broadcastAlunosValue(item.totalEnviados)} · ${broadcastFormatDate(item.enviadoEm)}',
      tips: [
        FxHelpTip('Mensagem', item.mensagem, icon: 'message-circle'),
      ],
    );
  }
}
