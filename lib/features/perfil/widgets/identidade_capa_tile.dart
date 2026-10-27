import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../dashboard/widgets/aluno_capa_banner.dart';
import '../utils/identidade_visual_display.dart';

/// Capa 16:9 do personal: mostra a imagem atual (ou um convite) e as ações de
/// adicionar, trocar e remover.
class IdentidadeCapaTile extends StatelessWidget {
  const IdentidadeCapaTile({
    super.key,
    required this.url,
    required this.uploading,
    required this.onEscolher,
    required this.onRemover,
  });

  final String? url;
  final bool uploading;
  final VoidCallback? onEscolher;
  final VoidCallback? onRemover;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final temCapa = (url ?? '').trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (temCapa)
          AlunoCapaBanner(url: url, altura: 120)
        else
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chrome.line.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(color: chrome.line),
            ),
            child:
                uploading
                    ? const FxLoading(size: 24)
                    : Icon(
                      Icons.panorama_outlined,
                      size: 34,
                      color: chrome.mute,
                    ),
          ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          identidadeCapaDica(),
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
        const SizedBox(height: TokensStrip.s2),
        Wrap(
          spacing: TokensStrip.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FxTonalButton(
              label: temCapa ? identidadeCapaTrocar() : identidadeCapaAdicionar(),
              icon: Icons.add_photo_alternate_outlined,
              loading: uploading,
              onPressed: onEscolher,
            ),
            if (temCapa)
              FxActionLink(
                label: identidadeCapaRemover(),
                destructive: true,
                onTap: onRemover,
              ),
          ],
        ),
      ],
    );
  }
}
