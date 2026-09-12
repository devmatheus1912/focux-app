part of 'migracao_magica_screen.dart';

class _MigracaoImportacaoResumoBody extends StatelessWidget {
  const _MigracaoImportacaoResumoBody({required this.data});

  final MigracaoImportacaoResumo data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final brand = Theme.of(context).colorScheme.primary;

    Widget stat(String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(TokensStrip.rSm),
          ),
          child: Column(
            children: [
              Text('$value', style: FocuxTypography.headline(color: color)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: mute, height: 1.3),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            stat('Importados', data.importados, brand),
            const SizedBox(width: 8),
            stat('Duplicados', data.duplicados, EagleTokens.warn),
            const SizedBox(width: 8),
            stat('Erros', data.erros, EagleTokens.bad),
          ],
        ),
        if (data.detalhes.isNotEmpty) ...[
          SizedBox(height: TokensStrip.s4),
          for (final item in data.detalhes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: switch (item.status) {
                        'IMPORTADO' => brand,
                        'DUPLICADO' => EagleTokens.warn,
                        _ => EagleTokens.bad,
                      },
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                            fontSize: 13,
                          ),
                        ),
                        if (item.motivo.isNotEmpty)
                          Text(
                            item.motivo,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: mute,
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
