import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';
import 'fx_inset_picker_option.dart';
import 'fx_settings_group.dart';

/// Item de uma sheet de seleção única ([showFxInsetPickerSheet]).
class FxInsetPickerSheetItem<T> {
  const FxInsetPickerSheetItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Sheet canônica de picker inset — paridade Perfil / `FxInsetPickerOption`.
Future<T?> showFxInsetPickerSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData? headerIcon,
  Color? iconColor,
  required List<FxInsetPickerSheetItem<T>> items,
  T? selected,
  bool Function(T a, T b)? sameValue,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;
  final soft = iconColor ?? BrandPalette.softened(primary);
  final equals = sameValue ?? (a, b) => a == b;
  final scrollable = items.length > 8;
  final maxHeight =
      MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

  return showFxHomeSheet<T>(
    context,
    builder: (ctx) {
      final group = FxSettingsGroup(
        accent: primary,
        edgeToEdgeRows: true,
        children: FxInsetPickerOption.list(
          accent: soft,
          items: [
            for (final item in items)
              FxInsetPickerOptionSpec(
                label: item.label,
                subtitle: item.subtitle,
                icon: item.icon,
                selected: selected != null && equals(selected, item.value),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(ctx).pop(item.value);
                },
              ),
          ],
        ),
      );

      return FxHomeSheetSurface(
        isDark: isDark,
        maxHeight: scrollable ? maxHeight : null,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            const SizedBox(height: 8),
            FxHomeSheetHeader(
              isDark: isDark,
              title: title,
              subtitle: subtitle,
              leading:
                  headerIcon == null
                      ? const SizedBox(width: 22, height: 22)
                      : Icon(headerIcon, color: soft, size: 20),
            ),
            const SizedBox(height: TokensStrip.s3),
            if (scrollable)
              Flexible(child: SingleChildScrollView(child: group))
            else
              group,
          ],
        ),
      );
    },
  );
}
