import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_icons.dart';
import '../theme/tokens_strip.dart';

/// Número grande com − e + embaixo, o mesmo da execução do treino: rótulo em
/// cima ("kg", "reps"), o valor no meio (toque para digitar, [onEditar]) e os
/// dois botões com metade da largura cada. Segurar o botão repete.
class FxValorStepper extends StatelessWidget {
  const FxValorStepper({
    super.key,
    required this.label,
    required this.value,
    required this.mute,
    required this.ink,
    required this.accent,
    this.onMinus,
    this.onPlus,
    this.onEditar,
  });

  final VoidCallback? onEditar;
  final String label;
  final String value;
  final Color mute;
  final Color ink;
  final Color accent;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        Semantics(
          button: onEditar != null,
          label: onEditar == null ? null : '$label: $value',
          excludeSemantics: onEditar != null,
          child: InkWell(
            onTap: onEditar,
            borderRadius: BorderRadius.circular(TokensStrip.rInput),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 64,
                minWidth: double.infinity,
              ),
              child: Center(
                // Cabe sempre numa linha: encolhe em vez de quebrar.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.cardTitle(color: ink).copyWith(
                      fontSize: TokensStrip.fontNumeroTela,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: TokensStrip.s1),
        Row(
          children: [
            Expanded(
              child: _FxValorStepperBotao(
                icon: FxIcons.remover,
                tooltip: s.checkinDiminuir(label),
                onPressed: onMinus,
                ink: ink,
                accent: accent,
              ),
            ),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: _FxValorStepperBotao(
                icon: FxIcons.adicionar,
                tooltip: s.checkinAumentar(label),
                onPressed: onPlus,
                ink: ink,
                accent: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Botão − ou +. Um toque soma um passo; segurar repete a cada 120 ms.
class _FxValorStepperBotao extends StatefulWidget {
  const _FxValorStepperBotao({
    required this.icon,
    required this.tooltip,
    required this.ink,
    required this.accent,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color ink;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  State<_FxValorStepperBotao> createState() => _FxValorStepperBotaoState();
}

class _FxValorStepperBotaoState extends State<_FxValorStepperBotao> {
  Timer? _repete;

  void _parar() {
    _repete?.cancel();
    _repete = null;
  }

  @override
  void dispose() {
    _parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: habilitado,
        label: widget.tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          onLongPressStart:
              !habilitado
                  ? null
                  : (_) {
                    _parar();
                    _repete = Timer.periodic(
                      const Duration(milliseconds: 120),
                      (_) {
                        HapticFeedback.selectionClick();
                        widget.onPressed!();
                      },
                    );
                  },
          onLongPressEnd: (_) => _parar(),
          onLongPressCancel: _parar,
          child: Material(
            color: widget.accent.withValues(alpha: habilitado ? 0.10 : 0.04),
            borderRadius: BorderRadius.circular(TokensStrip.rInput),
            child: InkWell(
              onTap: habilitado ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              child: SizedBox(
                height: 56,
                child: Center(
                  child: Icon(widget.icon, color: widget.ink, size: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
