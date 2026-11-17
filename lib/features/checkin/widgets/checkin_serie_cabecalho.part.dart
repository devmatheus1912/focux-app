part of 'checkin_exercise_widgets.dart';

/// Cabeçalho do cartão: a série de agora ("Válida 1 de 4 · Pirâmide ↑ ·
/// Drop-set"), a meta dela e, quando há técnica, o que fazer de diferente.
class _CabecalhoDaSerie extends StatelessWidget {
  const _CabecalhoDaSerie({required this.sa, required this.metodo, required this.brand});

  final SerieDeAgora sa;
  final MetodoExercicio metodo;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final meta = checkinMetaDaSerie(s, sa);
    final instrucao = checkinInstrucaoDaSerie(s, sa, metodo);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkinCabecalhoDaSerie(sa, metodo),
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
          ),
          if (meta.isNotEmpty)
            Text(meta, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
          if (instrucao != null) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(instrucao, style: FocuxHubTypography.bodyMuted(color: brand)),
          ],
        ],
      ),
    );
  }
}
