import 'package:flutter/material.dart';

import '../theme/fx_settings_layout.dart';
import 'fx_shell_scaffold.dart';

/// Grupo inset com [ListView.builder] — mesma pele de [FxSettingsGroup],
/// sem montar todas as linhas de uma vez.
class FxSettingsGroupedList extends StatelessWidget {
  const FxSettingsGroupedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(
      FxSettingsLayout.pageInset,
      8,
      FxSettingsLayout.pageInset,
      110,
    ),
    this.header,
    this.caption,
    this.accent,
    this.physics,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final String? header;
  final String? caption;
  final Color? accent;
  final ScrollPhysics? physics;

  int get _leadCount {
    var n = 0;
    if (header != null) n++;
    if (caption != null) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    final lead = _leadCount;
    return ListView.builder(
      padding: padding,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      itemCount: lead + itemCount,
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(
              left: FxSettingsLayout.groupPadH,
              right: FxSettingsLayout.groupPadH,
              bottom: FxSettingsLayout.headerToGroup,
            ),
            child: Text(
              header!,
              style: FxSettingsLayout.sectionHeader(color: mute),
            ),
          );
        }
        if (caption != null && index == (header != null ? 1 : 0)) {
          return Padding(
            padding: const EdgeInsets.only(
              left: FxSettingsLayout.groupPadH,
              right: FxSettingsLayout.groupPadH,
              bottom: FxSettingsLayout.headerToGroup,
            ),
            child: Text(
              caption!,
              style: FxSettingsLayout.footer(color: mute),
            ),
          );
        }
        final tileIndex = index - lead;
        final child = itemBuilder(context, tileIndex);
        if (child == null) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: fxListCardDecoration(
            context,
            accent: accent,
            radius: FxSettingsLayout.groupRadius,
          ).copyWith(borderRadius: _sliceRadius(tileIndex)),
          child: child,
        );
      },
    );
  }

  BorderRadius _sliceRadius(int index) {
    final radius = Radius.circular(FxSettingsLayout.groupRadius);
    if (itemCount == 1) return BorderRadius.all(radius);
    if (index == 0) return BorderRadius.vertical(top: radius);
    if (index == itemCount - 1) return BorderRadius.vertical(bottom: radius);
    return BorderRadius.zero;
  }
}
