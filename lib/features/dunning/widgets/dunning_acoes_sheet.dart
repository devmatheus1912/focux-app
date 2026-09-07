import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/dunning_repository.dart';
import '../utils/dunning_ops_display.dart';

Future<void> showDunningAcoesSheet(
  BuildContext context, {
  required DunningFalha falha,
  required VoidCallback onChat,
  required VoidCallback onCobrar,
  required VoidCallback onMarcar,
  VoidCallback? onAssinatura,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _DunningAcoesSheet(
          falha: falha,
          onChat: () {
            Navigator.of(ctx).pop();
            onChat();
          },
          onCobrar: () {
            Navigator.of(ctx).pop();
            onCobrar();
          },
          onMarcar: () {
            Navigator.of(ctx).pop();
            onMarcar();
          },
          onAssinatura:
              onAssinatura == null
                  ? null
                  : () {
                    Navigator.of(ctx).pop();
                    onAssinatura();
                  },
        ),
  );
}

class _DunningAcoesSheet extends StatelessWidget {
  const _DunningAcoesSheet({
    required this.falha,
    required this.onChat,
    required this.onCobrar,
    required this.onMarcar,
    this.onAssinatura,
  });

  final DunningFalha falha;
  final VoidCallback onChat;
  final VoidCallback onCobrar;
  final VoidCallback onMarcar;
  final VoidCallback? onAssinatura;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final hasAluno = dunningHasAluno(falha.alunoId);
    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            title: dunningFalhaTitulo(falha.alunoNome, falha.contexto),
            subtitle: dunningFalhaSubtitle(
              contexto: falha.contexto,
              alunoNome: falha.alunoNome,
              motivo: falha.motivo,
              tentativa: falha.tentativa,
            ),
            leading: Icon(Icons.warning_amber_outlined, size: 18, color: primary),
          ),
          const SizedBox(height: TokensStrip.s4),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              if (hasAluno)
                DashboardHomeActionChip(
                  label: 'Escrever',
                  accent: primary,
                  isDark: isDark,
                  onPressed: onChat,
                ),
              if (hasAluno)
                DashboardHomeActionChip(
                  label: 'Cobrar',
                  accent: EagleTokens.moneyGreen,
                  isDark: isDark,
                  onPressed: onCobrar,
                ),
              if (!hasAluno && onAssinatura != null)
                DashboardHomeActionChip(
                  label: 'Assinatura',
                  accent: primary,
                  isDark: isDark,
                  onPressed: onAssinatura!,
                ),
              DashboardHomeActionChip(
                label: 'Marcar recuperada',
                accent: EagleTokens.bad,
                isDark: isDark,
                onPressed: onMarcar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
