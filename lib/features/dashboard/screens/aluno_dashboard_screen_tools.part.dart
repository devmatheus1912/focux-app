part of 'aluno_dashboard_screen.dart';

/// Pendência e oferta. Sem os dois, a Home não mostra “Mais”.
void abrirHomeAlunoMais(
  BuildContext context, {
  required AlunoHomeView view,
  required DateTime hoje,
  required ValueChanged<AlunoPendencia> onPendencia,
  required void Function(AlunoPendencia) onPendenciaShown,
}) {
  final blocos = <Widget>[
    if (view.pendencias.isNotEmpty)
      AlunoPendenciasBlock(
        pendencias: view.pendencias,
        hoje: hoje,
        onTap: onPendencia,
        onShown: onPendenciaShown,
      ),
    if (view.ofertas.isNotEmpty) AlunoUpsellCarousel(ofertas: view.ofertas),
  ];
  if (blocos.isEmpty) return;

  showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return FxHomeSheetSurface(
        isDark: isDark,
        expand: true,
        child: ListView(
          children: [
            FxHomeSheetHandle(isDark: isDark),
            const SizedBox(height: TokensStrip.s4),
            ...blocos,
          ],
        ),
      );
    },
  );
}
