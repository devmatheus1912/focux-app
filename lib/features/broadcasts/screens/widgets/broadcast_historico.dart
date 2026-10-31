import 'package:flutter/material.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/shell_chrome.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_empty_state.dart';
import '../../../../core/widgets/fx_home_sheet.dart';
import '../../../../core/widgets/fx_settings_group.dart';
import '../../../../core/widgets/fx_settings_tile.dart';
import '../../../../core/widgets/fx_sheet_frame.dart';
import '../../../../core/widgets/fx_tonal_button.dart';
import '../../data/broadcast_repository.dart';
import '../../utils/broadcast_display.dart';
import '../../../../l10n/pt.dart';

class BroadcastHistorico extends StatelessWidget {
  const BroadcastHistorico({
    super.key,
    required this.itens,
    required this.onUsarDeNovo,
  });

  final List<Broadcast> itens;
  final ValueChanged<Broadcast> onUsarDeNovo;

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

  Future<void> _abrir(BuildContext context, Broadcast item) async {
    final reusar = await showFxHomeSheet<bool>(
      context,
      builder: (ctx) {
        final chrome = ShellChrome.of(ctx);
        return FxSheetFrame(
          title: item.titulo,
          subtitle:
              '${broadcastPublicoLabel(item.tipoConsultoriaAlvo)} · ${broadcastAlunosValue(item.totalEnviados, comPush: item.totalComPush)} · ${broadcastFormatDate(item.enviadoEm)}',
          footer: Padding(
            padding: const EdgeInsets.all(TokensStrip.s3),
            child: FxTonalButton(
              label: ptS.broadcastUsarDeNovo,
              expanded: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s3),
            child: Text(
              item.mensagem,
              style: FocuxHubTypography.body(color: chrome.ink),
            ),
          ),
        );
      },
    );
    if (reusar == true) onUsarDeNovo(item);
  }
}
