import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../chat/providers/chat_rascunho_provider.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/fx_icons.dart';

/// Ficha atribuída sem exercícios: explica por que ainda não dá para iniciar
/// (sem isso o aluno lê como "não abriu") e deixa avisar o personal.
Future<void> showTreinoPreparacaoSheet(
  BuildContext context,
  WidgetRef ref, {
  required String treinoNome,
}) {
  // "Avisar meu personal": abre o chat com a mensagem pronta.
  void onAvisar() {
    ref.read(chatAlunoRascunhoProvider.notifier).value =
        S.of(context).treinosPreparacaoMensagem(treinoNome);
    openAlunoRoute(context, '/chat/aluno');
  }

  final s = S.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;
  final chrome = ShellChrome.forBrightness(context, isDark);

  return showFxHomeSheet<void>(
    context,
    builder:
        (sheetContext) => FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: treinoNome,
                subtitle: s.treinosDestaqueEmPreparacao,
                leading: Icon(
                  FxIcons.pendente,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              Container(
                padding: const EdgeInsets.all(TokensStrip.s4),
                decoration: chrome.panel(accent: primary),
                child: Text(
                  s.treinosPreparacaoSheetTexto,
                  style: FocuxHubTypography.bodyMuted(
                    color: chrome.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.42,
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              FxLiquidPrimaryButton(
                label: s.treinosPreparacaoSheetCta,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: TokensStrip.s2),
              FxTonalButton(
                label: s.treinosPreparacaoAvisar,
                icon: FxIcons.chat,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onAvisar();
                },
              ),
            ],
          ),
        ),
  );
}
