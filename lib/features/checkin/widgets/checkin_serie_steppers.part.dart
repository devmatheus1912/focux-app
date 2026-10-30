part of 'checkin_exercise_widgets.dart';

/// Carga e reps lado a lado. Cada campo é uma coluna com a largura toda da
/// metade: rótulo, número enorme (toque para digitar) e, embaixo, os botões
/// − e + com metade da largura cada. Segurar o botão repete.
class _CheckinSetSteppers extends StatelessWidget {
  const _CheckinSetSteppers({
    required this.cargaKg,
    required this.reps,
    this.onPlusCarga,
    this.onMinusCarga,
    this.onPlusReps,
    this.onMinusReps,
    this.onEditarCarga,
    this.onEditarReps,
    this.cargaAnteriorKg,
  });

  final ValueChanged<double>? onEditarCarga;
  final ValueChanged<int>? onEditarReps;
  final double? cargaKg;

  /// Carga da última sessão: atalho "mesma da última vez" no teclado.
  final double? cargaAnteriorKg;
  final int? reps;
  final VoidCallback? onPlusCarga;
  final VoidCallback? onMinusCarga;
  final VoidCallback? onPlusReps;
  final VoidCallback? onMinusReps;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final brand = Theme.of(context).colorScheme.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _CheckinStepper(
              label: s.checkinStepperKg,
              // O rótulo "kg" já está acima do número: sem a unidade ele não quebra.
              value: cargaKg == null ? '—' : fxNumberPadTexto(cargaKg),
              onMinus: onMinusCarga,
              onPlus: onPlusCarga,
              onEditar:
                  onEditarCarga == null
                      ? null
                      : () async {
                        final v = await _pedirNumero(
                          context,
                          titulo: s.checkinStepperKg,
                          inicial: cargaKg,
                          decimal: true,
                          ultima: cargaAnteriorKg,
                          sufixo: s.checkinStepperKg,
                        );
                        if (v != null) onEditarCarga!(v);
                      },
              mute: chrome.mute,
              ink: chrome.ink,
              accent: brand,
            ),
          ),
          VerticalDivider(
            width: TokensStrip.s4,
            thickness: 1,
            color: chrome.mute.withValues(alpha: 0.22),
          ),
          Expanded(
            child: _CheckinStepper(
              label: s.checkinStepperReps,
              value: reps == null ? '—' : '$reps',
              onMinus: onMinusReps,
              onPlus: onPlusReps,
              onEditar:
                  onEditarReps == null
                      ? null
                      : () async {
                        final v = await _pedirNumero(
                          context,
                          titulo: s.checkinStepperReps,
                          inicial: reps?.toDouble(),
                          decimal: false,
                          sufixo: s.checkinStepperReps,
                        );
                        if (v != null) onEditarReps!(v.round());
                      },
              mute: chrome.mute,
              ink: chrome.ink,
              accent: brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckinStepper extends StatelessWidget {
  const _CheckinStepper({
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
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
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
              child: _CheckinStepperButton(
                icon: Icons.remove_rounded,
                tooltip: s.checkinDiminuir(label),
                onPressed: onMinus,
                ink: ink,
                accent: accent,
              ),
            ),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: _CheckinStepperButton(
                icon: Icons.add_rounded,
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
class _CheckinStepperButton extends StatefulWidget {
  const _CheckinStepperButton({
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
  State<_CheckinStepperButton> createState() => _CheckinStepperButtonState();
}

class _CheckinStepperButtonState extends State<_CheckinStepperButton> {
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

/// Pede o número em folha com teclado numérico; nulo ao fechar sem confirmar.
Future<double?> _pedirNumero(
  BuildContext context, {
  required String titulo,
  required double? inicial,
  required bool decimal,
  double? ultima,
  String? sufixo,
}) async {
  final s = S.of(context);
  final r = await showFxNumberPadSheet(
    context,
    titulo: titulo,
    confirmarLabel: MaterialLocalizations.of(context).okButtonLabel,
    sufixo: sufixo,
    inicial: inicial,
    decimal: decimal,
    maximo: decimal ? 500 : 50,
    atalhos: [
      if (ultima != null)
        (
          label: s.checkinUltimaVez(
            '${fxNumberPadTexto(ultima)} ${s.checkinStepperKg}',
          ),
          valor: ultima,
        ),
    ],
  );
  return r?.valor;
}
