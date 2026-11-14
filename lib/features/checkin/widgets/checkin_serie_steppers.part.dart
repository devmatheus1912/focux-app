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
            child: FxValorStepper(
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
            child: FxValorStepper(
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
