import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_entry_motion.dart';
import '../../dashboard/utils/dashboard_haptic.dart';
import '../../dashboard/utils/dashboard_readability.dart';

/// Colapsável quiet — paridade Home: **um** card; expandido = header + filho
/// no mesmo bloco (sem card dentro de card).
class PerfilQuietCollapsible extends StatefulWidget {
  const PerfilQuietCollapsible({
    super.key,
    required this.title,
    required this.collapsedHint,
    required this.isDark,
    required this.child,
    this.collapsedPreview,
    this.initiallyExpanded = false,
  });

  final String title;
  final String collapsedHint;
  final String? collapsedPreview;
  final bool isDark;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<PerfilQuietCollapsible> createState() => _PerfilQuietCollapsibleState();
}

class _PerfilQuietCollapsibleState extends State<PerfilQuietCollapsible> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    dashboardHapticCollapseToggle();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final heading = BrandPalette.sectionHeading(primary, dark: widget.isDark);
    final link = BrandPalette.sectionLink(primary, dark: widget.isDark);
    final caption = dashboardReadableCaption(context, isDark: widget.isDark);
    final motion = dashboardMotionDuration(context);
    final line = ShellChrome.forDark(widget.isDark).line;

    return DecoratedBox(
      decoration: fxStripCardDecoration(
        context,
        radius: TokensStrip.rCard,
        glowStrength: 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              expanded: _expanded,
              label:
                  _expanded
                      ? '${widget.title}. Recolher'
                      : '${widget.title}. ${widget.collapsedHint}. Expandir',
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(TokensStrip.rCard),
                  bottom:
                      _expanded
                          ? Radius.zero
                          : const Radius.circular(TokensStrip.rCard),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: FocuxHubTypography.bodyMuted(
                                color: heading,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            if (!_expanded) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.collapsedHint,
                                style: FocuxHubTypography.bodyMuted(
                                  color: caption,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.collapsedPreview != null &&
                                  widget.collapsedPreview!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.collapsedPreview!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: caption,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: link,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: motion,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child:
                _expanded
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(height: 1, thickness: 0.5, color: line),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: widget.child,
                        ),
                      ],
                    )
                    : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
