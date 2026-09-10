part of 'perfil_aluno_editar_screen.dart';

class _ProgressEntryCard extends StatelessWidget {
  final MedidaCorporal medida;
  final bool isDark;
  final String Function(String value) formatarData;

  const _ProgressEntryCard({
    required this.medida,
    required this.isDark,
    required this.formatarData,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chips = <Widget>[
      if (medida.peso != null)
        _MiniValueChip(
          label: 'Peso',
          value: '${medida.peso!.toStringAsFixed(1)} kg',
        ),
      if (medida.cintura != null)
        _MiniValueChip(
          label: 'Cintura',
          value: '${medida.cintura!.toStringAsFixed(1)} cm',
        ),
      if (medida.quadril != null)
        _MiniValueChip(
          label: 'Quadril',
          value: '${medida.quadril!.toStringAsFixed(1)} cm',
        ),
      if (medida.braco != null)
        _MiniValueChip(
          label: 'Braco',
          value: '${medida.braco!.toStringAsFixed(1)} cm',
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatarData(medida.data),
                style: TextStyle(
                  color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (medida.fotoUrl != null && medida.fotoUrl!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Com foto',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (chips.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          if (medida.fotoUrl != null && medida.fotoUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Image.network(medida.fotoUrl!, fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniValueChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValueChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FocuxHubTypography.bodyMuted(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: FocuxHubTypography.bodyMuted(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.requiredField = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: FxInputDeco.build(context, label, icon: icon),
        validator:
            requiredField
                ? (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Obrigatorio.'
                        : null
                : null,
      ),
    );
  }
}
