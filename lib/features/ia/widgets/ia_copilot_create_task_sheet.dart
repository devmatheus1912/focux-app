import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../providers/ia_copilot_providers.dart';
import '../utils/ia_copiloto_display.dart';
import 'ia_copilot_shell_widgets.dart';

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

    return FxHomeSheetScaffold(
      isDark: dark,
      leading: Icon(
        Icons.assignment_turned_in_outlined,
        color: brand,
        size: 18,
      ),
      title: 'Criar tarefa para ${alunoNome ?? 'aluno'}?',
      subtitle:
          'Vai para o ${FocuxMicrocopy.commandCenter}. Nada é aplicado automaticamente.',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          void submit() {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(ctx).pop(
              IaCopilotTaskDraft(
                acao: text,
                motivo: motivoInicial.trim(),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ação',
                style: TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
                  hintText: 'Descreva a tarefa para revisar depois',
                  hintStyle: TextStyle(color: mute),
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
                style: TextStyle(
                  color: ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: TokensStrip.s3),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IaCopilotMetaChip(
                    label: 'Destino: ${FocuxMicrocopy.commandCenter}',
                    icon: Icons.space_dashboard_outlined,
                    brand: brand,
                    ink: ink,
                    line: line,
                  ),
                  IaCopilotMetaChip(
                    label: 'Prioridade P1',
                    icon: Icons.flag_outlined,
                    brand: brand,
                    ink: ink,
                    line: line,
                  ),
                  IaCopilotMetaChip(
                    label: 'SLA 24h',
                    icon: Icons.timer_outlined,
                    brand: brand,
                    ink: ink,
                    line: line,
                  ),
                ],
              ),
              if (motivoInicial.trim().isNotEmpty) ...[
                const SizedBox(height: TokensStrip.s3),
                Text(
                  motivoInicial,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
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
