import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/winback_repository.dart';
import '../utils/winback_display.dart';

Future<void> showWinbackAcoesSheet(
  BuildContext context, {
  required WinbackLogEntry entry,
  required VoidCallback onAluno,
  required VoidCallback onChat,
  required VoidCallback onCobrar,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _WinbackAcoesSheet(
          entry: entry,
          onAluno: () {
            Navigator.of(ctx).pop();
            onAluno();
          },
          onChat: () {
            Navigator.of(ctx).pop();
            onChat();
          },
          onCobrar: () {
            Navigator.of(ctx).pop();
            onCobrar();
          },
        ),
  );
}

class _WinbackAcoesSheet extends StatelessWidget {
  const _WinbackAcoesSheet({
    required this.entry,
    required this.onAluno,
    required this.onChat,
    required this.onCobrar,
  });

  final WinbackLogEntry entry;
  final VoidCallback onAluno;
  final VoidCallback onChat;
  final VoidCallback onCobrar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            title: winbackAlunoLabel(entry.alunoNome),
            subtitle: winbackTipoLabel(entry.tipo),
            leading: Icon(Icons.person_outline, size: 18, color: primary),
          ),
          const SizedBox(height: TokensStrip.s4),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              DashboardHomeActionChip(
                label: 'Escrever',
                accent: primary,
                isDark: isDark,
                onPressed: onChat,
              ),
              DashboardHomeActionChip(
                label: 'Cobrar',
                accent: EagleTokens.moneyGreen,
                isDark: isDark,
                onPressed: onCobrar,
              ),
              DashboardHomeActionChip(
                label: 'Abrir 360',
                accent: primary,
                isDark: isDark,
                onPressed: onAluno,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
