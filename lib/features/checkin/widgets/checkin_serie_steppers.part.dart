part of 'checkin_exercise_widgets.dart';

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
      children: [
        Text(
          label,
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TokensStrip.s1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CheckinStepperButton(
              icon: Icons.remove_rounded,
              tooltip: s.checkinDiminuir(label),
              onPressed: onMinus,
              ink: ink,
              accent: accent,
            ),
            Expanded(
              child: Semantics(
                button: onEditar != null,
                label: onEditar == null ? null : '$label: $value',
                excludeSemantics: onEditar != null,
                child: InkWell(
                  onTap: onEditar,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Center(
                      // Cabe sempre numa linha: encolhe em vez de quebrar.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                        value,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        // Número grande: lido de longe, com a mão ocupada.
                        style: FocuxHubTypography.metric(
                          color: ink,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _CheckinStepperButton(
              icon: Icons.add_rounded,
              tooltip: s.checkinAumentar(label),
              onPressed: onPlus,
              ink: ink,
              accent: accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckinStepperButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: accent.withValues(alpha: 0.08),
        minimumSize: const Size(
          checkinExecutionControlMin,
          checkinExecutionControlMin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
        ),
      ),
      icon: Icon(icon),
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
