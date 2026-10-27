import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_sheet_search_field.dart';
import '../../../core/widgets/fx_inset_picker_option.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/enums.dart';

Future<T?> showAddExercicioEnumPicker<T extends Enum>(
  BuildContext context, {
  required String title,
  required String contextLabel,
  required IconData icon,
  Color? iconColor,
  required List<T> values,
  required Map<T, String> labels,
  T? selected,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showFxHomeSheet<T>(
    context,
    builder:
        (ctx) => _AddExercicioEnumPickerSheet<T>(
          isDark: isDark,
          title: title,
          contextLabel: contextLabel,
          icon: icon,
          iconColor: iconColor,
          values: values,
          labels: labels,
          selected: selected,
        ),
  );
}

class _AddExercicioEnumPickerSheet<T extends Enum> extends StatefulWidget {
  const _AddExercicioEnumPickerSheet({
    required this.isDark,
    required this.title,
    required this.contextLabel,
    required this.icon,
    this.iconColor,
    required this.values,
    required this.labels,
    required this.selected,
  });

  final bool isDark;
  final String title;
  final String contextLabel;
  final IconData icon;
  final Color? iconColor;
  final List<T> values;
  final Map<T, String> labels;
  final T? selected;

  @override
  State<_AddExercicioEnumPickerSheet<T>> createState() =>
      _AddExercicioEnumPickerSheetState<T>();
}

class _AddExercicioEnumPickerSheetState<T extends Enum>
    extends State<_AddExercicioEnumPickerSheet<T>> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    if (_query.isEmpty) return widget.values;
    return widget.values.where((item) {
      final label = widget.labels[item] ?? item.backendName;
      return label.toLowerCase().contains(_query);
    }).toList();
  }

  Widget _optionsList(List<T> filtered, Color primary, Color soft) {
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          _query.isEmpty
              ? 'Nenhuma opção.'
              : 'Nenhum resultado para “$_query”.',
          style: FxSettingsLayout.footer(color: fxScreenMute(context)),
        ),
      );
    }

    return FxSettingsGroup(
      accent: primary,
      edgeToEdgeRows: true,
      children: FxInsetPickerOption.list(
        accent: soft,
        items: [
          for (final item in filtered)
            FxInsetPickerOptionSpec(
              label: widget.labels[item] ?? item.backendName,
              selected: item == widget.selected,
              onTap: () => Navigator.of(context).pop(item),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final soft = widget.iconColor ?? BrandPalette.softened(primary);
    final filtered = _filtered;
    final showSearch = widget.values.length > 5;

    Widget options = _optionsList(filtered, primary, soft);

    if (showSearch) {
      options = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxSheetSearchField(
            dica: 'Buscar opção',
            controller: _searchCtrl,
            onChanged: (_) {},
          ),
          const SizedBox(height: TokensStrip.s3),
          options,
        ],
      );
    }

    return FxSheetFrame(
      title: widget.title,
      subtitle: widget.contextLabel,
      leading: Icon(widget.icon, color: soft, size: 20),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: options,
      ),
    );
  }
}
