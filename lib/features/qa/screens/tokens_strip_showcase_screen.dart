import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_components.dart';

/// QA board — visual reference for TOKENS STRIP v1.0.0 (debug only).
class TokensStripShowcaseScreen extends StatefulWidget {
  const TokensStripShowcaseScreen({super.key});

  @override
  State<TokensStripShowcaseScreen> createState() =>
      _TokensStripShowcaseScreenState();
}

class _TokensStripShowcaseScreenState extends State<TokensStripShowcaseScreen> {
  bool _toggleOn = true;
  int _tabIndex = 0;
  int _page = 1;
  bool _dropdownOpen = false;
  bool _loadingBtn = false;
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'TOKENS STRIP',
        subtitle: 'Design system reference · v${TokensStrip.version}',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBadge(version: TokensStrip.version),
            const SizedBox(height: TokensStrip.s5),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 720;
                return Wrap(
                  spacing: TokensStrip.s4,
                  runSpacing: TokensStrip.s4,
                  children: [
                    _panel(wide, 1, 'Typography', _TypographyPanel(isDark: isDark)),
                    _panel(wide, 1, 'Icon set', _IconGrid(primary: primary)),
                    _panel(wide, 1, 'Spacing scale', const _SpacingTable()),
                    _panel(wide, 1, 'Border weights', _BorderWeights(primary: primary)),
                    _panel(wide, 1, 'Corner radius', _CornerRadius(primary: primary)),
                    _panel(wide, 1, 'Shadow depth', const _ShadowDepth()),
                    _panel(
                      wide,
                      2,
                      'Surface elevation',
                      _ElevationStrip(isDark: isDark, primary: primary),
                    ),
                    _panel(wide, 1, 'Buttons', _ButtonsPanel(
                      loading: _loadingBtn,
                      onLoadingTap: () {
                        setState(() => _loadingBtn = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _loadingBtn = false);
                        });
                      },
                    )),
                    _panel(wide, 1, 'Inputs', _InputsPanel(obscure: _obscure, onToggleObscure: () => setState(() => _obscure = !_obscure))),
                    _panel(wide, 1, 'Toggle', _TogglePanel(value: _toggleOn, onChanged: (v) => setState(() => _toggleOn = v))),
                    _panel(wide, 1, 'Tabs', _TabsPanel(index: _tabIndex, onChanged: (i) => setState(() => _tabIndex = i))),
                    _panel(wide, 1, 'Chips', const _ChipsPanel()),
                    _panel(wide, 1, 'Date picker mini', _MiniCalendar(primary: primary)),
                    _panel(wide, 1, 'Dropdown', _DropdownPanel(
                      open: _dropdownOpen,
                      onToggle: () => setState(() => _dropdownOpen = !_dropdownOpen),
                    )),
                    _panel(wide, 2, 'Stepper / Steps', const FxStripStepper(currentStep: 0, labels: ['Label progress', 'Label progress', 'Label progress'])),
                    _panel(wide, 2, 'Component anatomy: button', const _ButtonAnatomy()),
                    _panel(wide, 2, 'Notifications', const _ToastPreview()),
                    _panel(wide, 1, 'Tooltip', const _TooltipPreview()),
                    _panel(wide, 1, 'Badge', const _BadgeRow()),
                    _panel(wide, 2, 'Pagination', FxStripPagination(page: _page, totalPages: 5, onPage: (p) => setState(() => _page = p))),
                    _panel(wide, 2, 'Breadcrumbs', const FxStripBreadcrumbs(segments: ['Navigation', 'Sub-page', 'Trail'])),
                    _panel(wide, 1, 'Card', _SpecCard(primary: primary, isDark: isDark)),
                    _panel(wide, 2, 'Table row', _TablePreview(primary: primary, isDark: isDark)),
                    _panel(wide, 2, 'Empty state', FxStripEmptyState(
                      icon: Icons.terrain_outlined,
                      title: 'Illustration and message',
                      message: 'This state is a message alone to use it in order to focus user activity.',
                      actionLabel: 'Learn more',
                      onAction: () {},
                    )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(bool wide, int cols, String title, Widget child) {
    final width = wide ? (720 / 2 * cols) - TokensStrip.s4 : double.infinity;
    return SizedBox(
      width: width,
      child: _ShowcaseSection(title: title, child: child),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.version});
  final String version;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'TOKENS STRIP',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: TokensStrip.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: TokensStrip.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
            border: Border.all(color: TokensStrip.primary.withValues(alpha: 0.35)),
          ),
          child: Text(
            'v$version',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TokensStrip.primaryHover,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowcaseSection extends StatelessWidget {
  const _ShowcaseSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: BoxDecoration(
        color: TokensStrip.cardBg,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: TokensStrip.borderDefault),
        boxShadow: TokensStrip.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TokensStrip.primary,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          child,
        ],
      ),
    );
  }
}

class _TypographyPanel extends StatelessWidget {
  const _TypographyPanel({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('H1: System OS', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 8),
        Text('H2: Section Title', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: TokensStrip.primary)),
        const SizedBox(height: 8),
        Text('Body: Default text', style: GoogleFonts.outfit(fontSize: 15, color: ink)),
        const SizedBox(height: 8),
        Text(
          'The quick brown fox jumps over the lazy dog. 0123456789',
          style: GoogleFonts.outfit(fontSize: 13, color: mute, height: 1.4),
        ),
      ],
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.primary});
  final Color primary;

  static const _icons = [
    Icons.settings_outlined,
    Icons.hub_outlined,
    Icons.copy_all_outlined,
    Icons.share_outlined,
    Icons.description_outlined,
    Icons.swap_vert_rounded,
    Icons.folder_outlined,
    Icons.insert_drive_file_outlined,
    Icons.subdirectory_arrow_right_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: _icons.map((i) => Icon(i, color: primary, size: 22)).toList(),
    );
  }
}

class _SpacingTable extends StatelessWidget {
  const _SpacingTable();

  static const _rows = [
    (4, TokensStrip.s1),
    (8, TokensStrip.s2),
    (12, TokensStrip.s3),
    (16, TokensStrip.s4),
    (24, TokensStrip.s5),
    (32, TokensStrip.s6),
    (48, TokensStrip.s7),
    (64, TokensStrip.s8),
    (80, TokensStrip.s9),
  ];

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      children: _rows.map((r) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('${r.$1}', style: _cell()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(width: r.$2, height: 8, color: TokensStrip.primary.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text('${r.$2.toInt()}px', style: _cell()),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  TextStyle _cell() => GoogleFonts.jetBrainsMono(fontSize: 11, color: TokensStrip.textSecondary);
}

class _BorderWeights extends StatelessWidget {
  const _BorderWeights({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [0.5, 1.0, 1.5, 2.0, 3.0].map((w) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(height: w, color: primary),
        );
      }).toList(),
    );
  }
}

class _CornerRadius extends StatelessWidget {
  const _CornerRadius({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [4.0, 8.0, 12.0, 50.0].map((r) {
        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(r),
                ),
                border: Border.all(color: primary),
              ),
            ),
            const SizedBox(height: 4),
            Text('${r.toInt()}', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: TokensStrip.textSecondary)),
          ],
        );
      }).toList(),
    );
  }
}

class _ShadowDepth extends StatelessWidget {
  const _ShadowDepth();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _box(TokensStrip.cardShadow(), Colors.white, 'Light'),
        _box([
          BoxShadow(color: Colors.pink.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4)),
        ], Colors.pink.withValues(alpha: 0.08), 'Medium'),
        _box([
          BoxShadow(color: Colors.blue.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
        ], Colors.blue.withValues(alpha: 0.08), 'Strong'),
      ],
    );
  }

  Widget _box(List<BoxShadow> shadows, Color fill, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8), boxShadow: shadows),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: TokensStrip.textSecondary)),
      ],
    );
  }
}

class _ElevationStrip extends StatelessWidget {
  const _ElevationStrip({required this.isDark, required this.primary});
  final bool isDark;
  final Color primary;

  static const _levels = [0, 1, 2, 3, 4, 6, 8, 12, 24, 32, 48, 64, 96];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _levels.map((dp) {
          final selected = dp == 3;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TokensStrip.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? primary : TokensStrip.borderDefault,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: TokensStrip.elevation(dp.clamp(0, 48), dark: isDark, accent: primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$dp', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: TokensStrip.textSecondary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ButtonsPanel extends StatelessWidget {
  const _ButtonsPanel({required this.loading, required this.onLoadingTap});
  final bool loading;
  final VoidCallback onLoadingTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FxLiquidPrimaryButton(label: 'Primary', icon: Icons.check_rounded, onPressed: () {}),
        const SizedBox(height: 10),
        FxSecondaryButton(label: 'Secondary', onPressed: () {}),
        const SizedBox(height: 10),
        FxSecondaryButton(label: 'Disabled', onPressed: null),
        const SizedBox(height: 10),
        FxLiquidPrimaryButton(label: 'Loading', loading: loading, onPressed: loading ? null : onLoadingTap),
      ],
    );
  }
}

class _InputsPanel extends StatelessWidget {
  const _InputsPanel({required this.obscure, required this.onToggleObscure});
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(decoration: FxInputDeco.build(context, 'text or profile', hint: 'text or profile')),
        const SizedBox(height: 10),
        TextField(
          obscureText: obscure,
          decoration: FxInputDeco.build(context, 'Password', hint: 'Password').copyWith(
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: FxInputDeco.build(context, 'Search', hint: 'Search', icon: Icons.search_rounded),
        ),
      ],
    );
  }
}

class _TogglePanel extends StatelessWidget {
  const _TogglePanel({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(children: [Switch(value: true, onChanged: (_) {}), const Text('On', style: TextStyle(fontSize: 11))]),
        Column(children: [Switch(value: false, onChanged: (_) {}), const Text('Off', style: TextStyle(fontSize: 11))]),
        Column(children: [Switch(value: value, onChanged: onChanged), const Text('Live', style: TextStyle(fontSize: 11))]),
      ],
    );
  }
}

class _TabsPanel extends StatelessWidget {
  const _TabsPanel({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        _tab(context, 'Active', 0, primary, filled: true),
        _tab(context, 'Inactive', 1, primary, filled: false),
        _tab(context, 'Disabled', 2, primary, filled: false, disabled: true),
      ],
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    int i,
    Color primary, {
    required bool filled,
    bool disabled = false,
  }) {
    final selected = index == i && !disabled;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => onChanged(i),
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected && filled ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(TokensStrip.rButton),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: disabled
                      ? TokensStrip.disabled
                      : (selected && filled ? Colors.white : TokensStrip.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipsPanel extends StatelessWidget {
  const _ChipsPanel();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FxStripChip(label: 'Filter', onDismiss: () {}),
        FxStripChip(label: 'Action', onDismiss: () {}),
        Opacity(
          opacity: 0.45,
          child: FxStripChip(label: 'Disabled', onTap: null),
        ),
      ],
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    const days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    const grid = [
      [29, 30, 31, 1, 2, 3, 4],
      [5, 6, 7, 8, 9, 10, 11],
      [12, 13, 14, 15, 16, 17, 18],
      [19, 20, 21, 22, 23, 24, 25],
      [26, 27, 28, 29, 30, 1, 2],
    ];

    Widget dayCell(int d) {
      final is10 = d == 10;
      final is13 = d == 13;
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: is10 ? primary : (is13 ? Colors.transparent : null),
          shape: BoxShape.circle,
          border: is13 ? Border.all(color: primary, width: 2) : null,
        ),
        child: Text(
          '$d',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: is10 ? Colors.white : TokensStrip.textPrimary,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.chevron_left, size: 18, color: primary),
            Text('June 2022', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
            Icon(Icons.chevron_right, size: 18, color: primary),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) => Text(d, style: TextStyle(fontSize: 10, color: TokensStrip.textSecondary))).toList(),
        ),
        const SizedBox(height: 4),
        ...grid.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: row.map(dayCell).toList(),
          ),
        )),
      ],
    );
  }
}

class _DropdownPanel extends StatelessWidget {
  const _DropdownPanel({required this.open, required this.onToggle});
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: TokensStrip.borderDefault),
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
            ),
            child: Row(
              children: [
                const Expanded(child: Text('Select options', style: TextStyle(fontSize: 13))),
                Icon(open ? Icons.expand_less : Icons.expand_more, size: 20, color: TokensStrip.textSecondary),
              ],
            ),
          ),
        ),
        if (open) ...[
          const SizedBox(height: 4),
          ...['Select options', 'Select options', 'Select options', 'Select options'].map((o) => ListTile(
            dense: true,
            title: Text(o, style: const TextStyle(fontSize: 13)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          )),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
            ),
            child: const ListTile(
              dense: true,
              title: Text('Active menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ],
    );
  }
}

class _ButtonAnatomy extends StatelessWidget {
  const _ButtonAnatomy();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        _row('IDLE STATE', OutlinedButton(onPressed: () {}, child: const Text('Engage'))),
        _row('ICON LEFT', OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.star_outline, size: 16), label: const Text('ICON'))),
        _row('HOVER STATE', FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: TokensStrip.primaryHover), child: const Text('HOVER STATE'))),
        _row('DISABLED', OutlinedButton(onPressed: null, child: const Text('Engage'))),
        _row('LOADING', SizedBox(height: 44, child: Center(child: FxLoading(color: primary)))),
      ],
    );
  }

  Widget _row(String label, Widget button) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: TokensStrip.textSecondary))),
          Expanded(child: button),
        ],
      ),
    );
  }
}

class _ToastPreview extends StatelessWidget {
  const _ToastPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TokensStrip.cardBg,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: TokensStrip.borderDefault),
        boxShadow: TokensStrip.cardShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(color: EagleTokens.goodSoft, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: EagleTokens.good, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toast message', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Additional text if granted', style: TextStyle(fontSize: 11, color: TokensStrip.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.close_rounded, size: 18, color: TokensStrip.textSecondary),
        ],
      ),
    );
  }
}

class _TooltipPreview extends StatelessWidget {
  const _TooltipPreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TokensStrip.cardBg,
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          border: Border.all(color: TokensStrip.borderDefault),
          boxShadow: TokensStrip.cardShadow(),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.blue),
            SizedBox(width: 6),
            Text('Small info bubble', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            FxStripBadge(kind: FxStripBadgeKind.error),
            FxStripBadge(kind: FxStripBadgeKind.success),
            FxStripBadge(kind: FxStripBadgeKind.info),
            FxStripBadge(kind: FxStripBadgeKind.warning),
            FxStripBadge(kind: FxStripBadgeKind.notification),
          ],
        ),
        const SizedBox(height: 6),
        Text('Status', style: GoogleFonts.outfit(fontSize: 10, color: TokensStrip.textSecondary)),
      ],
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({required this.primary, required this.isDark});
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TITLE', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: primary, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        Text('Content block title', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 6),
        Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
          style: GoogleFonts.outfit(fontSize: 12.5, color: TokensStrip.textSecondary, height: 1.45),
        ),
      ],
    );
  }
}

class _TablePreview extends StatelessWidget {
  const _TablePreview({required this.primary, required this.isDark});
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    TextStyle head() => GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: primary);
    TextStyle cell() => GoogleFonts.outfit(fontSize: 12, color: ink);

    Widget row(List<String> cells, {bool header = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: TokensStrip.borderDefault.withValues(alpha: 0.7))),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(cells[0], style: header ? head() : cell())),
            Expanded(child: Text(cells[1], style: header ? head() : cell())),
            Expanded(child: Text(cells[2], style: header ? head() : cell())),
            Expanded(child: Text(cells[3], style: header ? head().copyWith(color: primary) : TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 12))),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(['Name', 'Data', 'Last row', 'Actions'], header: true),
        row(['Data entry ver 1', '2023', r'$29.99', 'Actions']),
        row(['Data entry ver 2', '2023', r'$49.99', 'Actions']),
      ],
    );
  }
}
