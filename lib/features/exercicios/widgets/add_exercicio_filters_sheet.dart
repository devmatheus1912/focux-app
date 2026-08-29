import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/enums.dart';
import '../data/exercicio_taxonomy_labels.dart';

typedef AddExercicioFiltersResult = ({
  Set<Equipamento> equipamentos,
  Set<Espaco> espacos,
});

Future<AddExercicioFiltersResult?> showAddExercicioFiltersSheet(
  BuildContext context, {
  required Set<Equipamento> equipamentos,
  required Set<Espaco> espacos,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showFxHomeSheet<AddExercicioFiltersResult>(
    context,
    builder:
        (ctx) => _AddExercicioFiltersSheet(
          isDark: isDark,
          initialEquipamentos: equipamentos,
          initialEspacos: espacos,
        ),
  );
}

class _AddExercicioFiltersSheet extends StatefulWidget {
  const _AddExercicioFiltersSheet({
    required this.isDark,
    required this.initialEquipamentos,
    required this.initialEspacos,
  });

  final bool isDark;
  final Set<Equipamento> initialEquipamentos;
  final Set<Espaco> initialEspacos;

  @override
  State<_AddExercicioFiltersSheet> createState() =>
      _AddExercicioFiltersSheetState();
}

class _AddExercicioFiltersSheetState extends State<_AddExercicioFiltersSheet> {
  late Set<Equipamento> _equipamentos;
  late Set<Espaco> _espacos;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _equipamentos = Set<Equipamento>.from(widget.initialEquipamentos);
    _espacos = Set<Espaco>.from(widget.initialEspacos);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(String label) {
    if (_query.isEmpty) return true;
    return label.toLowerCase().contains(_query);
  }

  void _toggleEquipamento(Equipamento value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_equipamentos.contains(value)) {
        _equipamentos.remove(value);
      } else {
        _equipamentos.add(value);
      }
    });
  }

  void _toggleEspaco(Espaco value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_espacos.contains(value)) {
        _espacos.remove(value);
      } else {
        _espacos.add(value);
      }
    });
  }

  void _apply() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop((
      equipamentos: Set<Equipamento>.from(_equipamentos),
      espacos: Set<Espaco>.from(_espacos),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);

    final equipamentosVisiveis =
        Equipamento.values
            .where(
              (e) => _matches(TaxonomyLabels.equipamento[e] ?? e.backendName),
            )
            .toList();
    final espacosVisiveis =
        Espaco.values
            .where((e) => _matches(TaxonomyLabels.espaco[e] ?? e.backendName))
            .toList();

    return FxHomeSheetScaffold(
      isDark: widget.isDark,
      leading: Icon(Icons.inventory_2_outlined, color: soft, size: 22),
      title: 'Equipamentos e espaços',
      subtitle:
          '${_equipamentos.length} equip. · ${_espacos.length} espaço${_espacos.length == 1 ? '' : 's'}',
      trailing: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.close_rounded, color: mute),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Buscar equipamento ou espaço',
            child: TextField(
              controller: _searchCtrl,
              style: FxSettingsLayout.rowLabel(color: ink),
              decoration: FxInputDeco.insetGrouped(
                context,
                icon: Icons.search_rounded,
                hint: 'Buscar…',
                iconColor: soft,
              ),
            ),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxSettingsGroup(
            header: 'Equipamentos',
            caption:
                _equipamentos.isEmpty
                    ? 'Opcional — ajuda a filtrar na biblioteca.'
                    : '${_equipamentos.length} selecionado${_equipamentos.length == 1 ? '' : 's'}',
            accent: primary,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child:
                    equipamentosVisiveis.isEmpty
                        ? Text(
                          _query.isEmpty
                              ? 'Nenhum equipamento.'
                              : 'Nenhum resultado para “$_query”.',
                          style: FxSettingsLayout.footer(color: mute),
                        )
                        : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in equipamentosVisiveis)
                              _FilterChip(
                                label:
                                    TaxonomyLabels.equipamento[item] ??
                                    item.backendName,
                                selected: _equipamentos.contains(item),
                                onTap: () => _toggleEquipamento(item),
                              ),
                          ],
                        ),
              ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxSettingsGroup(
            header: 'Espaços',
            caption:
                _espacos.isEmpty
                    ? 'Onde o exercício pode ser executado.'
                    : '${_espacos.length} selecionado${_espacos.length == 1 ? '' : 's'}',
            accent: primary,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child:
                    espacosVisiveis.isEmpty
                        ? Text(
                          _query.isEmpty
                              ? 'Nenhum espaço.'
                              : 'Nenhum resultado para “$_query”.',
                          style: FxSettingsLayout.footer(color: mute),
                        )
                        : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in espacosVisiveis)
                              _FilterChip(
                                label:
                                    TaxonomyLabels.espaco[item] ??
                                    item.backendName,
                                selected: _espacos.contains(item),
                                onTap: () => _toggleEspaco(item),
                              ),
                          ],
                        ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DashboardHomeActionChip(
              label: 'Aplicar',
              accent: primary,
              isDark: widget.isDark,
              onPressed: _apply,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: selected,
        checkmarkColor: Colors.white,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 9 : 8,
          vertical: 5,
        ),
        labelStyle: TextStyle(
          color:
              selected
                  ? Colors.white
                  : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary),
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        selectedColor: primary,
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.035) : TokensStrip.pageBg,
        side: BorderSide(
          color:
              selected
                  ? primary
                  : (isDark
                      ? EagleTokens.darkLine
                      : TokensStrip.borderDefault.withValues(alpha: 0.72)),
        ),
      ),
    );
  }
}
