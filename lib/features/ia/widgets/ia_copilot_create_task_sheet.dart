import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../dashboard/utils/copilot_actions_display.dart';
import '../providers/ia_copilot_providers.dart';
import '../utils/ia_copiloto_display.dart';
import '../../../core/theme/fx_icons.dart';

Future<IaCopilotTaskDraft?> showIaCopilotCreateTaskSheet(
  BuildContext context, {
  required String? alunoNome,
  required String acaoInicial,
  required String motivoInicial,
}) async {
  final controller = TextEditingController(text: acaoInicial);
  final result = await showFxHomeSheet<IaCopilotTaskDraft>(
    context,
    builder: (ctx) {
      return _IaCopilotCreateTaskSheet(
        alunoNome: alunoNome,
        motivoInicial: motivoInicial,
        controller: controller,
      );
    },
  );
  controller.dispose();
  return result;
}

class _IaCopilotCreateTaskSheet extends StatelessWidget {
  const _IaCopilotCreateTaskSheet({
    required this.alunoNome,
    required this.motivoInicial,
    required this.controller,
  });

  final String? alunoNome;
  final String motivoInicial;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final cardBg = dark ? EagleTokens.darkCard : TokensStrip.cardBg;
    // Tarefa do Copiloto nasce P1: o mesmo prazo de Tarefas.
    final prazo = copilotActionsPrazo('P1').selo;

    return FxHomeSheetScaffold(
      isDark: dark,
      leading: Icon(FxIcons.pranchetaFeita, color: brand, size: 18),
      title: 'Criar tarefa para ${alunoNome ?? 'o aluno'}?',
      subtitle:
          'Vai para ${FocuxMicrocopy.commandCenter}. Nada é enviado ao aluno.',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          void submit() {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(ctx).pop(
              IaCopilotTaskDraft(acao: text, motivo: motivoInicial.trim()),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // O motivo é o contexto: vem antes do campo.
              if (motivoInicial.trim().isNotEmpty) ...[
                Text(
                  motivoInicial.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
                const SizedBox(height: TokensStrip.s3),
              ],
              Text('Tarefa', style: FocuxHubTypography.chip(ink)),
              const SizedBox(height: TokensStrip.s2),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setSheetState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cardBg,
                  hintText: 'O que fazer com este aluno',
                  hintStyle: FocuxHubTypography.body(color: mute),
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: line),
                  ),
                  focusedBorder: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: brand, width: 1.2),
                  ),
                ),
                style: FocuxHubTypography.body(color: ink),
              ),
              if (prazo != null) ...[
                const SizedBox(height: TokensStrip.s2),
                Text(
                  'Prazo: ${prazo.toLowerCase()}',
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
              ],
              const SizedBox(height: TokensStrip.s4),
              FxLiquidPrimaryButton(
                label: iaCopilotoCriarTarefaLabel(),
                onPressed: controller.text.trim().isEmpty ? null : submit,
              ),
            ],
          );
        },
      ),
    );
  }
}
