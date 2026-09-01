part of 'plano_alimentar_detail_screen.dart';

class PlanoAlimentarMacroHeader extends StatelessWidget {
  const PlanoAlimentarMacroHeader({super.key, required this.plano});

  final PlanoAlimentar plano;

  @override
  Widget build(BuildContext context) {
    final p = plano;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: DecoratedBox(
        decoration: fxListCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (p.caloriasDia != null)
                    _MacroChip('${p.caloriasDia} kcal', EagleTokens.warn),
                  if (p.proteinaG != null)
                    _MacroChip('${p.proteinaG}g prot', EagleTokens.bad),
                  if (p.carboidratoG != null)
                    _MacroChip('${p.carboidratoG}g carbo', EagleTokens.warn),
                  if (p.gorduraG != null)
                    _MacroChip('${p.gorduraG}g gord', EagleTokens.macroFat),
                ],
              ),
              _MacroBar(
                proteinaG: p.proteinaG,
                carboidratoG: p.carboidratoG,
                gorduraG: p.gorduraG,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
    backgroundColor: color.withValues(alpha: 0.12),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _MacroBar extends StatelessWidget {
  final int? proteinaG;
  final int? carboidratoG;
  final int? gorduraG;

  const _MacroBar({
    required this.proteinaG,
    required this.carboidratoG,
    required this.gorduraG,
  });

  @override
  Widget build(BuildContext context) {
    final proteinKcal = (proteinaG ?? 0) * 4;
    final carbKcal = (carboidratoG ?? 0) * 4;
    final fatKcal = (gorduraG ?? 0) * 9;
    final totalKcal = proteinKcal + carbKcal + fatKcal;

    if (totalKcal <= 0) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 8,
        margin: const EdgeInsets.only(top: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            if (proteinKcal > 0)
              Flexible(
                flex: proteinKcal,
                child: Container(color: EagleTokens.macroProtein),
              ),
            if (carbKcal > 0)
              Flexible(
                flex: carbKcal,
                child: Container(color: EagleTokens.warn),
              ),
            if (fatKcal > 0)
              Flexible(
                flex: fatKcal,
                child: Container(color: EagleTokens.macroCarb),
              ),
          ],
        ),
      ),
    );
  }
}

class PlanoAlimentarRefeicaoCard extends StatelessWidget {
  final Refeicao refeicao;
  final VoidCallback onDelete;
  const PlanoAlimentarRefeicaoCard({
    super.key,
    required this.refeicao,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = refeicao;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: fxListCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.nomeRefeicao,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (r.horario != null)
                    Text(
                      r.horario!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Remover refeição',
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: chrome.mute),
                  ),
                ],
              ),
              if (r.calorias != null) ...[
                const SizedBox(height: 6),
                Text(
                  alimentarRefeicaoKcalLabel(r.calorias),
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (r.proteinaG != null ||
                  r.carboG != null ||
                  r.gorduraG != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    if (r.proteinaG != null)
                      _MacroChip('${r.proteinaG}g prot', EagleTokens.bad),
                    if (r.carboG != null)
                      _MacroChip('${r.carboG}g carbo', EagleTokens.warn),
                    if (r.gorduraG != null)
                      _MacroChip('${r.gorduraG}g gord', EagleTokens.macroFat),
                  ],
                ),
              ],
              if (r.alimentos != null && r.alimentos!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  r.alimentos!,
                  style: TextStyle(color: chrome.mute, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
