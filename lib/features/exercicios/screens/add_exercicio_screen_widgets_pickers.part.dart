part of 'add_exercicio_screen.dart';

class _EnumPickerCompact<T extends Enum> extends StatelessWidget {
  final String title;
  final List<T> values;
  final Map<T, String> labels;
  final T? selected;

  const _EnumPickerCompact({
    required this.title,
    required this.values,
    required this.labels,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth > 420 ? 360.0 : constraints.maxWidth - 40;
          return Center(
            child: Container(
              width: width,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 12),
              decoration: fxListCardDecoration(context, accent: primary),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Novo exercício',
                              style: TextStyle(
                                color: mute,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: TextStyle(
                                color: ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${values.length}',
                          style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: mute),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...values.map((item) {
                    final isSelected = item == selected;
                    final itemLabel = labels[item] ?? item.backendName;
                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: itemLabel,
                      child: Material(
                        color:
                            isSelected
                                ? primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: isSelected ? primary : mute,
                                  size: 21,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    itemLabel,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 14,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EnumPickerFullScreen<T extends Enum> extends StatefulWidget {
  final String title;
  final List<T> values;
  final Map<T, String> labels;
  final T? selected;
  final double maxHeight;

  const _EnumPickerFullScreen({
    required this.title,
    required this.values,
    required this.labels,
    required this.selected,
    required this.maxHeight,
  });

  @override
  State<_EnumPickerFullScreen<T>> createState() =>
      _EnumPickerFullScreenState<T>();
}

class _EnumPickerFullScreenState<T extends Enum>
    extends State<_EnumPickerFullScreen<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primary = Theme.of(context).colorScheme.primary;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final filtered =
        widget.values.where((item) {
          final label = widget.labels[item] ?? item.backendName;
          return label.toLowerCase().contains(_query.toLowerCase().trim());
        }).toList();

    return ColoredBox(
      color: isDark ? EagleTokens.darkBg : TokensStrip.pageBg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(TokensStrip.s5, 8, 20, 12 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : TokensStrip.borderDefault,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Novo exercício',
                          style: TextStyle(
                            color: mute,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.35,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: FocuxTypography.headline(color: ink).copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Semantics(
                    button: true,
                    label: 'Fechar seletor',
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: mute),
                    ),
                  ),
                ],
              ),
              if (widget.values.length > 8) ...[
                const SizedBox(height: 14),
                Semantics(
                  textField: true,
                  label: 'Buscar ${widget.title.toLowerCase()}',
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar opção',
                      prefixIcon: Icon(Icons.search_rounded, color: mute),
                      filled: true,
                      fillColor:
                          isDark ? EagleTokens.darkCard : TokensStrip.pageBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? EagleTokens.darkLine
                                  : TokensStrip.borderDefault,
                        ),
                      ),
                      enabledBorder: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? EagleTokens.darkLine
                                  : TokensStrip.borderDefault,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder:
                      (_, __) => Divider(
                        height: 1,
                        color:
                            isDark
                                ? EagleTokens.darkLine
                                : TokensStrip.borderDefault.withValues(
                                  alpha: 0.72,
                                ),
                      ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final selected = item == widget.selected;
                    final itemLabel = widget.labels[item] ?? item.backendName;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: itemLabel,
                      child: fxListTileCardShell(
                        context: context,
                        margin: EdgeInsets.zero,
                        accent: selected ? primary : null,
                        selected: selected,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          minLeadingWidth: 28,
                          leading: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected ? primary : mute,
                            size: 21,
                          ),
                          title: Text(
                            itemLabel,
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
