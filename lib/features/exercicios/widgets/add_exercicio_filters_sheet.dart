import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
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
    setState(() {
      if (_equipamentos.contains(value)) {
        _equipamentos.remove(value);
      } else {
        _equipamentos.add(value);
      }
    });
  }

  void _toggleEspaco(Espaco value) {
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

  Widget _chipWrap({
    required List<Widget> children,
    required String emptyMessage,
  }) {
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          emptyMessage,
          style: FxSettingsLayout.footer(color: fxScreenMute(context)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final ink = fxScreenInk(context);
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

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

    final summary =
        '${_equipamentos.length} equip. · ${_espacos.length} espaço${_espacos.length == 1 ? '' : 's'}';

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: widget.isDark),
          const SizedBox(height: 8),
          FxHomeSheetHeader(
            isDark: widget.isDark,
            title: 'Equipamentos e espaços',
            subtitle: summary,
            leading: Icon(Icons.inventory_2_outlined, color: soft, size: 20),
          ),
          const SizedBox(height: TokensStrip.s3),
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
          const SizedBox(height: TokensStrip.s3),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxSettingsGroup(
                    header: 'Equipamentos',
                    caption:
                        _equipamentos.isEmpty
                            ? 'Opcional — ajuda a filtrar na biblioteca.'
                            : '${_equipamentos.length} selecionado${_equipamentos.length == 1 ? '' : 's'}',
                    accent: primary,
                    children: [
                      _chipWrap(
                        emptyMessage:
                            _query.isEmpty
                                ? 'Nenhum equipamento.'
                                : 'Nenhum resultado para “$_query”.',
                        children: [
                          for (final item in equipamentosVisiveis)
                            FxToggleChip(
                              expanded: true,
                              label:
                                  TaxonomyLabels.equipamento[item] ??
                                  item.backendName,
                              selected: _equipamentos.contains(item),
                              isDark: widget.isDark,
                              showCheckmark: true,
                              onTap: () => _toggleEquipamento(item),
                            ),
                        ],
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
                      _chipWrap(
                        emptyMessage:
                            _query.isEmpty
                                ? 'Nenhum espaço.'
                                : 'Nenhum resultado para “$_query”.',
                        children: [
                          for (final item in espacosVisiveis)
                            FxToggleChip(
                              expanded: true,
                              label:
                                  TaxonomyLabels.espaco[item] ??
                                  item.backendName,
                              selected: _espacos.contains(item),
                              isDark: widget.isDark,
                              showCheckmark: true,
                              onTap: () => _toggleEspaco(item),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FxLiquidPrimaryButton(
            label: 'Aplicar',
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}
