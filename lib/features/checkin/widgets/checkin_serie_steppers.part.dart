part of 'checkin_exercise_widgets.dart';

class _CheckinSetSteppers extends StatelessWidget {
  const _CheckinSetSteppers({
    required this.cargaKg,
    required this.reps,
    this.onPlusCarga,
    this.onMinusCarga,
    this.onPlusReps,
    this.onMinusReps,
  });

  final double? cargaKg;
  final int? reps;
  final VoidCallback? onPlusCarga;
  final VoidCallback? onMinusCarga;
  final VoidCallback? onPlusReps;
  final VoidCallback? onMinusReps;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = Theme.of(context).colorScheme.primary;
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _CheckinStepper(
              label: 'kg',
              value: checkinCargaLabel(cargaKg) ?? '—',
              onMinus: onMinusCarga,
              onPlus: onPlusCarga,
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
              label: 'reps',
              value: reps == null ? '—' : '$reps',
              onMinus: onMinusReps,
              onPlus: onPlusReps,
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
  });

  final String label;
  final String value;
  final Color mute;
  final Color ink;
  final Color accent;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
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
              tooltip: 'Diminuir $label',
              onPressed: onMinus,
              ink: ink,
              accent: accent,
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.sectionTitle(context, color: ink),
              ),
            ),
            _CheckinStepperButton(
              icon: Icons.add_rounded,
              tooltip: 'Aumentar $label',
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

/// Postura: rótulo + `FxHelpIconButton` canônico (não outlined genérico).
class _CheckinPosturaHelp extends StatelessWidget {
  const _CheckinPosturaHelp({required this.onTap, required this.ink});

  final VoidCallback onTap;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s2,
        vertical: TokensStrip.s1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Postura',
            style: FocuxHubTypography.bodyMuted(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: FxHelpChrome.gap),
          FxHelpIconButton(
            tooltip: 'Ajuda de postura',
            onTap: onTap,
            expandHitTarget: true,
          ),
        ],
      ),
    );
  }
}
