import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../../perfil/widgets/perfil_public_link_sheet.dart';
import '../../../core/theme/fx_icons.dart';

/// Linha discreta no fim da lista quando há poucos alunos: abre "Seu código".
class AlunosConvideMais extends ConsumerWidget {
  const AlunosConvideMais({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final perfil = ref.watch(perfilProvider).value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Convide mais alunos',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ),
          FxTonalButton(
            label: 'Enviar código',
            icon: FxIcons.chave,
            compact: true,
            onPressed:
                perfil == null
                    ? null
                    : () => showPerfilCodigoSheet(context, perfil: perfil),
          ),
        ],
      ),
    );
  }
}
