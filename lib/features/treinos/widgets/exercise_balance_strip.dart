import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../screens/widgets/exercise_picker_filter_bar.dart';
import '../utils/exercise_balance.dart';

/// "No treino: Peito 3 · Tríceps 1", com um aviso discreto de antagonista.
/// Tocar num grupo liga o chip do mesmo grupo na lista.
class ExerciseBalanceStrip extends StatefulWidget {
  const ExerciseBalanceStrip({
    super.key,
    required this.balanco,
    required this.selecionados,
    required this.onToggle,
    required this.primary,
    required this.isDark,
  });

  final Map<GrupoMuscular, int> balanco;
  final Set<GrupoMuscular> selecionados;
  final ValueChanged<GrupoMuscular> onToggle;
  final Color primary;
  final bool isDark;

  static const dispensaKey = 'add_balanco_aviso_dispensado';

  @override
  State<ExerciseBalanceStrip> createState() => _ExerciseBalanceStripState();
}

class _ExerciseBalanceStripState extends State<ExerciseBalanceStrip> {
  bool _avisoDispensado = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final off = prefs.getBool(ExerciseBalanceStrip.dispensaKey) ?? false;
      if (mounted && off) setState(() => _avisoDispensado = true);
    });
  }

  Future<void> _dispensar() async {
    setState(() => _avisoDispensado = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ExerciseBalanceStrip.dispensaKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.balanco.isEmpty) return const SizedBox.shrink();
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final entradas =
        widget.balanco.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final aviso = _avisoDispensado ? null : avisoAntagonista(widget.balanco);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: 'Exercícios por grupo no treino',
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'No treino:',
                        style: FocuxHubTypography.bodyMuted(
                          color: mute,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  for (final e in entradas) ...[
                    ExercisePickerChip(
                      label:
                          '${TaxonomyLabels.grupo[e.key] ?? e.key.name} ${e.value}',
                      selected: widget.selecionados.contains(e.key),
                      primary: widget.primary,
                      isDark: widget.isDark,
                      onTap: () => widget.onToggle(e.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          if (aviso != null)
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: mute),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    aviso,
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  ),
                ),
                IconButton(
                  tooltip: 'Dispensar aviso',
                  visualDensity: VisualDensity.compact,
                  onPressed: _dispensar,
                  icon: Icon(Icons.close_rounded, size: 18, color: mute),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
