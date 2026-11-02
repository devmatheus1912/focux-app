import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../l10n/pt.dart';

/// Foto em tela cheia, com zoom. Excluir fica no "⋯", à vista de quem pode.
Future<void> abrirFotoEmTelaCheia(
  BuildContext context, {
  required String url,
  required String legenda,
  VoidCallback? onExcluir,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _FotoTelaCheia(url: url, legenda: legenda, onExcluir: onExcluir),
  ),
);

class _FotoTelaCheia extends StatelessWidget {
  const _FotoTelaCheia({required this.url, required this.legenda, this.onExcluir});

  final String url;
  final String legenda;
  final VoidCallback? onExcluir;

  Future<void> _acoes(BuildContext context) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.evolucaoFotoAcoes,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'excluir',
            rotulo: ptS.evolucaoFotoExcluir,
            icone: Icons.delete_outline_rounded,
            perigo: true,
          ),
        ]),
      ],
    );
    if (escolha != 'excluir' || !context.mounted) return;
    Navigator.pop(context);
    onExcluir?.call();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: ptS.evolucaoFotoFechar,
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  legenda,
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.bodyMuted(color: Colors.white),
                ),
              ),
              if (onExcluir != null)
                IconButton(
                  tooltip: ptS.evolucaoFotoAcoes,
                  color: Colors.white,
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () => _acoes(context),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: FxCachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
