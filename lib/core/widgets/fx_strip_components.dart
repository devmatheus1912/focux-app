import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';
import '../theme/tokens_strip.dart';
import 'fx_motion.dart';

/// TOKENS STRIP v1.0.0 — secondary pill button (white + teal border).
class FxSecondaryButton extends StatelessWidget {
  const FxSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rButton),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s5,
          vertical: TokensStrip.s3,
        ),
      ),
    );
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

/// TOKENS STRIP chip — teal outline or filled filter pill.
class FxStripChip extends StatelessWidget {
  const FxStripChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDismiss,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rButton),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color:
                selected
                    ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
            border: Border.all(
              color: selected ? primary : primary.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(Icons.close_rounded, size: 14, color: primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge icons from TOKENS STRIP spec.
enum FxStripBadgeKind { error, success, info, warning, notification }

class FxStripBadge extends StatelessWidget {
  const FxStripBadge({super.key, required this.kind, this.size = 28});

  final FxStripBadgeKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (kind) {
      FxStripBadgeKind.error => (EagleTokens.bad, Icons.close_rounded),
      FxStripBadgeKind.success => (EagleTokens.good, Icons.check_rounded),
      FxStripBadgeKind.info => (TokensStrip.primary, Icons.info_outline_rounded),
      FxStripBadgeKind.warning => (EagleTokens.warn, Icons.warning_amber_rounded),
      FxStripBadgeKind.notification => (
        EagleTokens.gold,
        Icons.notifications_none_rounded,
      ),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, size: size * 0.48, color: color),
    );
  }
}

/// Horizontal stepper — 3-step TOKENS STRIP pattern.
class FxStripStepper extends StatelessWidget {
  const FxStripStepper({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final done = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              color: done ? primary : mute.withValues(alpha: 0.25),
            ),
          );
        }
        final step = i ~/ 2;
        final active = step <= currentStep;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: active ? primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? primary : mute.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: active ? Colors.white : mute,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labels[step],
              style: TextStyle(fontSize: 10.5, color: mute),
            ),
          ],
        );
      }),
    );
  }
}

/// Breadcrumb trail — teal separators.
class FxStripBreadcrumbs extends StatelessWidget {
  const FxStripBreadcrumbs({super.key, required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          Text(
            segments[i],
            style: GoogleFonts.outfit(
              color: primary.withValues(alpha: i == segments.length - 1 ? 1 : 0.72),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          if (i < segments.length - 1)
            Icon(Icons.chevron_right_rounded, size: 16, color: primary.withValues(alpha: 0.5)),
        ],
      ],
    );
  }
}

/// Simple pagination control.
class FxStripPagination extends StatelessWidget {
  const FxStripPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget pageBtn(int n) {
      final selected = n == page;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPage(n),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              '$n',
              style: TextStyle(
                color: selected ? primary : mute,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        for (var i = 1; i <= totalPages.clamp(1, 5); i++) pageBtn(i),
        if (totalPages > 5) Text('…', style: TextStyle(color: mute)),
        IconButton(
          onPressed: page < totalPages ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// TOKENS STRIP empty state with optional primary CTA.
class FxStripEmptyState extends StatelessWidget {
  const FxStripEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                border: Border.all(color: primary.withValues(alpha: 0.25)),
                boxShadow: TokensStrip.cardShadow(dark: isDark),
              ),
              child: Icon(icon, color: primary, size: 32),
            ),
            const SizedBox(height: TokensStrip.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: TokensStrip.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 13.5, height: 1.4),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TokensStrip.s5),
              FxLiquidPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
