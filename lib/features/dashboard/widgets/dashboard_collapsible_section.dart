import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_haptic.dart';
import '../utils/dashboard_readability.dart';

class DashboardCollapsibleSection extends StatefulWidget {
  const DashboardCollapsibleSection({
    super.key,
    required this.title,
    required this.collapsedHint,
    required this.isDark,
    required this.child,
    this.initiallyExpanded = false,
    this.headerActionLabel,
    this.onHeaderAction,
  });

  final String title;
  final String collapsedHint;
  final bool isDark;
  final Widget child;
  final bool initiallyExpanded;
  final String? headerActionLabel;
  final VoidCallback? onHeaderAction;

  @override
  State<DashboardCollapsibleSection> createState() =>
      _DashboardCollapsibleSectionState();
}

class _DashboardCollapsibleSectionState
    extends State<DashboardCollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant DashboardCollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded &&
        !oldWidget.initiallyExpanded &&
        widget.initiallyExpanded) {
      _expanded = true;
    }
  }

  void _toggle() {
    dashboardHapticCollapseToggle();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: widget.isDark);
    final mute = dashboardReadableMuted(context, isDark: widget.isDark);
    final link = BrandPalette.sectionLink(primary, dark: widget.isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              expanded: _expanded,
              label: dashboardCollapsibleSemanticsLabel(
                widget.title,
                _expanded,
                collapsedHint: widget.collapsedHint,
              ),
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: fxStripCardDecoration(
                    context,
                    radius: TokensStrip.rCard,
                    glowStrength: 0.08,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: AppTypography.inter(
                                fontSize: TokensStrip.fontH2,
                                fontWeight: TokensStrip.weightH2,
                                letterSpacing: TokensStrip.trackingH2,
                                color: heading,
                                height: 1.2,
                              ),
                            ),
                            if (!_expanded) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.collapsedHint,
                                style: AppTypography.inter(
                                  fontSize: TokensStrip.fontBodySm,
                                  fontWeight: FontWeight.w500,
                                  color: mute,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.headerActionLabel != null &&
                          widget.onHeaderAction != null)
                        Semantics(
                          button: true,
                          label: widget.headerActionLabel,
                          child: TextButton(
                            onPressed: widget.onHeaderAction,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Text(widget.headerActionLabel!),
                          ),
                        ),
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: link,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: widget.child,
            ),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
