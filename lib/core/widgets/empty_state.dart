import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Premium empty state with animated icon, structured hierarchy, and optional CTA.
/// Replaces bare "Nenhum X" Center(Text) patterns across the app.
class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final inkColor = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final muteColor = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Floating icon with glass container ──
            AnimatedBuilder(
              animation: _float,
              builder:
                  (_, __) => Transform.translate(
                    offset: Offset(0, _float.value),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.12 : 0.07),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primary.withValues(
                            alpha: isDark ? 0.18 : 0.10,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 32,
                        color: primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
            ),

            const SizedBox(height: 28),

            // ── Title ──
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: inkColor,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 8),

            // ── Description ──
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: muteColor,
                  height: 1.5,
                ),
              ),
            ),

            // ── CTA Button ──
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                height: 44,
                child: FilledButton.tonal(
                  onPressed: widget.onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    foregroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
