import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../data/retencao_repository.dart';
import '../utils/retencao_display.dart';

Future<void> showRetencaoAcoesSheet(
  BuildContext context, {
  required RetencaoAlunoScore score,
  required VoidCallback onAluno,
  required VoidCallback onChat,
  required VoidCallback onCobrar,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _RetencaoAcoesSheet(
          score: score,
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

class _RetencaoAcoesSheet extends StatelessWidget {
  const _RetencaoAcoesSheet({
    required this.score,
    required this.onAluno,
    required this.onChat,
    required this.onCobrar,
  });

  final RetencaoAlunoScore score;
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
            title: score.alunoNome,
            subtitle: retencaoPorque(score),
            leading: Icon(Icons.favorite_outline, size: 18, color: primary),
          ),
          const SizedBox(height: TokensStrip.s4),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              FxActionChip(
                label: 'Escrever',
                accent: primary,
                isDark: isDark,
                onPressed: onChat,
                solid: true,
              ),
              FxActionChip(
                label: 'Cobrar',
                accent: primary,
                isDark: isDark,
                onPressed: onCobrar,
              ),
              FxActionChip(
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
