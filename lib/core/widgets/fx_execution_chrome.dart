import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';

/// S8: tela acesa enquanto a execução está montada (§9).
class FxExecutionKeepAwake extends StatefulWidget {
  const FxExecutionKeepAwake({super.key, required this.child});

  final Widget child;

  @override
  State<FxExecutionKeepAwake> createState() => _FxExecutionKeepAwakeState();
}

class _FxExecutionKeepAwakeState extends State<FxExecutionKeepAwake> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Back do SO não descarta a execução sem o caller decidir.
class FxExecutionPopGuard extends StatelessWidget {
  const FxExecutionPopGuard({
    super.key,
    required this.onLeave,
    required this.child,
  });

  final Future<void> Function() onLeave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onLeave();
      },
      child: child,
    );
  }
}

enum FxExecutionLeaveChoice {
  continuarDepois,
  encerrarAgora,
  descartar,
}

/// Sheet de saída do treino: retomar depois, encerrar parcial ou descartar.
Future<FxExecutionLeaveChoice?> showFxExecutionLeaveSheet(
  BuildContext context, {
  required bool hasProgress,
}) async {
  if (!hasProgress) return FxExecutionLeaveChoice.continuarDepois;

  return showFxHomeSheet<FxExecutionLeaveChoice>(
    context,
    builder:
        (ctx) => _FxExecutionLeaveSheet(
          onPick: (choice) => FxHomeSheetChrome.dismissAndPop(ctx, choice),
        ),
  );
}

/// Compat: retorna `true` só para sair mantendo a sessão (Continuar depois).
Future<bool> fxConfirmLeaveExecution(
  BuildContext context, {
  required bool hasProgress,
}) async {
  final choice = await showFxExecutionLeaveSheet(
    context,
    hasProgress: hasProgress,
  );
  return choice == FxExecutionLeaveChoice.continuarDepois;
}

class _FxExecutionLeaveSheet extends StatelessWidget {
  const _FxExecutionLeaveSheet({required this.onPick});

  final ValueChanged<FxExecutionLeaveChoice> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primary = theme.colorScheme.primary;

    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Sair do treino?',
            subtitle: 'Escolha o que fazer com esta sessão.',
            leading: Icon(Icons.fitness_center_rounded, color: primary, size: 18),
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(
            'Continuar depois mantém séries e tempo salvos. Encerrar agora '
            'registra o treino como concluído. Descartar apaga o progresso desta sessão.',
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          _leaveButton(
            context,
            label: 'Continuar depois',
            icon: Icons.pause_circle_outline_rounded,
            accent: primary,
            onPrimary: theme.colorScheme.onPrimary,
            onTap: () => onPick(FxExecutionLeaveChoice.continuarDepois),
          ),
          const SizedBox(height: TokensStrip.s2),
          _leaveButton(
            context,
            label: 'Encerrar agora',
            icon: Icons.flag_rounded,
            accent: primary,
            onPrimary: theme.colorScheme.onPrimary,
            onTap: () => onPick(FxExecutionLeaveChoice.encerrarAgora),
          ),
          const SizedBox(height: TokensStrip.s2),
          _leaveButton(
            context,
            label: 'Descartar',
            icon: Icons.delete_outline_rounded,
            accent: EagleTokens.bad,
            onPrimary: Colors.white,
            destructive: true,
            onTap: () => onPick(FxExecutionLeaveChoice.descartar),
          ),
          const SizedBox(height: TokensStrip.s2),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Voltar ao treino',
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaveButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color accent,
    required Color onPrimary,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          if (destructive) HapticFeedback.heavyImpact();
          onTap();
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
