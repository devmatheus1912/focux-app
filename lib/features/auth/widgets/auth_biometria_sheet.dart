import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_motion.dart';
import '../services/biometria_login.dart';

/// Pergunta, depois de um login com senha, se o aluno ou personal quer entrar
/// com biometria nas próximas vezes. `true` ativa; `false` ou fechar adia.
Future<bool?> showAuthBiometriaSheet(
  BuildContext context, {
  required BiometriaTipo tipo,
}) {
  return showFxHomeSheet<bool>(
    context,
    builder: (_) => _AuthBiometriaSheet(tipo: tipo),
  );
}

class _AuthBiometriaSheet extends StatelessWidget {
  const _AuthBiometriaSheet({required this.tipo});

  final BiometriaTipo tipo;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return FxSheetFrame(
      title: 'Entrar com ${tipo.rotulo}?',
      subtitle: 'Nas próximas vezes, um toque e pronto.',
      leading: Icon(
        tipo == BiometriaTipo.faceId
            ? Icons.face_unlock_outlined
            : Icons.fingerprint_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxLiquidPrimaryButton(
            label: 'Ativar ${tipo.rotulo}',
            onPressed: () => FxHomeSheetChrome.dismissAndPop(context, true),
          ),
          const SizedBox(height: TokensStrip.s2),
          FxTonalButton(
            label: 'Agora não',
            expanded: true,
            onPressed: () => FxHomeSheetChrome.dismissAndPop(context, false),
          ),
        ],
      ),
      child: Text(
        'Seu e-mail e senha ficam guardados só neste aparelho, protegidos pelo '
        'sistema, e só abrem depois de você confirmar com ${tipo.rotulo}. '
        'Dá para desligar quando quiser em Perfil.',
        style: FocuxHubTypography.body(color: chrome.mute),
      ),
    );
  }
}
