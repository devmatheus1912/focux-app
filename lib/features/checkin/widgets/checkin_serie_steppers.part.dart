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
  });

  final ValueChanged<double>? onEditarCarga;
  final ValueChanged<int>? onEditarReps;
  final double? cargaKg;
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
              value: checkinCargaLabel(cargaKg) ?? '—',
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
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: FocuxHubTypography.sectionTitle(
                          context,
                          color: ink,
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

/// Pede o número digitado (vírgula ou ponto); nulo ao cancelar ou se inválido.
Future<double?> _pedirNumero(
  BuildContext context, {
  required String titulo,
  required double? inicial,
  required bool decimal,
}) async {
  final ctrl = TextEditingController(
    text:
        inicial == null
            ? ''
            : (inicial.roundToDouble() == inicial
                ? inicial.toStringAsFixed(0)
                : inicial.toString().replaceAll('.', ',')),
  );
  final valor = await showDialog<double>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textInputAction: TextInputAction.done,
            onSubmitted:
                (v) => Navigator.pop(
                  ctx,
                  double.tryParse(v.trim().replaceAll(',', '.')),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed:
                  () => Navigator.pop(
                    ctx,
                    double.tryParse(ctrl.text.trim().replaceAll(',', '.')),
                  ),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
  );
  ctrl.dispose();
  return valor == null || valor < 0 ? null : valor;
}
