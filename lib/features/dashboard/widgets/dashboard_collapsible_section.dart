import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/dashboard_a11y.dart';
import '../utils/dashboard_entry_motion.dart';
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
    this.resetToken = 0,
    this.headerActionLabel,
    this.onHeaderAction,
    this.collapsedActionLabel,
    this.onCollapsedAction,
    this.collapsedPreview,
  });

  final String title;
  final String collapsedHint;
  final bool isDark;
  final Widget child;
  final bool initiallyExpanded;
  final int resetToken;
  final String? headerActionLabel;
  final VoidCallback? onHeaderAction;
  final String? collapsedActionLabel;
  final VoidCallback? onCollapsedAction;
  final String? collapsedPreview;

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
    if (oldWidget.resetToken != widget.resetToken) {
      _expanded = false;
      return;
    }
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

  void _onHeaderTap() {
    if (!_expanded &&
        widget.onCollapsedAction != null &&
        widget.collapsedActionLabel != null) {
      widget.onCollapsedAction!();
      return;
    }
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final motionDuration = dashboardMotionDuration(context);
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: widget.isDark);
    final mute = dashboardReadableMuted(context, isDark: widget.isDark);
    final link = BrandPalette.sectionLink(primary, dark: widget.isDark);
    final hasCollapsedAction =
        !_expanded &&
        widget.collapsedActionLabel != null &&
        widget.onCollapsedAction != null;

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
                collapsedActionLabel: widget.collapsedActionLabel,
              ),
              child: InkWell(
                onTap: _onHeaderTap,
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
                              if (widget.collapsedPreview != null &&
                                  widget.collapsedPreview!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.collapsedPreview!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    fontSize: TokensStrip.fontBodySm,
                                    fontWeight: FontWeight.w700,
                                    color: heading,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      if (_expanded &&
                          widget.headerActionLabel != null &&
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
                      if (hasCollapsedAction)
                        Semantics(
                          button: true,
                          label: widget.collapsedActionLabel,
                          child: TextButton(
                            onPressed: widget.onCollapsedAction,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              foregroundColor: link,
                            ),
                            child: Text(widget.collapsedActionLabel!),
                          ),
                        ),
                      Semantics(
                        button: true,
                        label: _expanded
                            ? 'Recolher ${widget.title}'
                            : 'Expandir ${widget.title}',
                        child: InkWell(
                          onTap: _toggle,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: AnimatedRotation(
                              turns: _expanded ? 0.25 : 0,
                              duration: motionDuration,
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                                color: link,
                              ),
                            ),
                          ),
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
            duration: motionDuration,
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
