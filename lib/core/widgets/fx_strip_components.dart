import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
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
    final enabled = onPressed != null;

    if (!enabled) {
      final button = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s5,
          vertical: TokensStrip.s3,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAED),
          borderRadius: BorderRadius.circular(TokensStrip.rButton),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      );
      if (!expand) return button;
      return SizedBox(width: double.infinity, child: button);
    }

    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: primary, width: 1.2),
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
                    ? TokensStrip.chipSelectedFill
                    : Colors.white,
            borderRadius: BorderRadius.circular(TokensStrip.rButton),
            border: Border.all(
              color: selected ? primary : primary.withValues(alpha: 0.55),
              width: selected ? 1.2 : 1,
            ),
            boxShadow:
                selected
                    ? TokensStrip.coloredDepthGlow(primary, strength: 0.22)
                    : null,
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
  const FxStripBadge({
    super.key,
    required this.kind,
    this.size = 36,
    this.showLabel = false,
    this.label = 'Status',
  });

  final FxStripBadgeKind kind;
  final double size;
  final bool showLabel;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (kind) {
      FxStripBadgeKind.error => (
        TokensStrip.badgeError,
        TokensStrip.badgeErrorBg,
        Icons.close_rounded,
      ),
      FxStripBadgeKind.success => (
        TokensStrip.badgeSuccess,
        TokensStrip.badgeSuccessBg,
        Icons.check_rounded,
      ),
      FxStripBadgeKind.info => (
        TokensStrip.badgeInfo,
        TokensStrip.badgeInfoBg,
        Icons.info_outline_rounded,
      ),
      FxStripBadgeKind.warning => (
        TokensStrip.badgeWarning,
        TokensStrip.badgeWarningBg,
        Icons.warning_amber_rounded,
      ),
      FxStripBadgeKind.notification => (
        TokensStrip.badgeNotify,
        TokensStrip.badgeNotifyBg,
        Icons.notifications_none_rounded,
      ),
    };

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: TokensStrip.coloredDepthGlow(color, strength: 0.55),
      ),
      child: Icon(icon, size: size * 0.46, color: color),
    );

    if (!showLabel) return badge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 10,
            color: TokensStrip.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Success toast — pale mint surface from TOKENS STRIP spec.
class FxStripToast extends StatelessWidget {
  const FxStripToast({
    super.key,
    this.title = 'Toast message',
    this.subtitle = 'Additional text if granted',
    this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TokensStrip.toastSuccessBg,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: TokensStrip.toastSuccessBorder, width: 1.2),
        boxShadow: TokensStrip.coloredDepthGlow(
          TokensStrip.badgeSuccess,
          strength: 0.25,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: TokensStrip.badgeSuccess.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: TokensStrip.badgeSuccess,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: TokensStrip.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.inter(
                    fontSize: 11.5,
                    color: TokensStrip.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: TokensStrip.textSecondary.withValues(alpha: 0.8),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

/// Info tooltip bubble with tail — TOKENS STRIP spec.
class FxStripTooltip extends StatelessWidget {
  const FxStripTooltip({super.key, this.message = 'Small info bubble'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TooltipBubblePainter(
        fill: TokensStrip.tooltipBg,
        border: TokensStrip.tooltipBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: TokensStrip.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: TokensStrip.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipBubblePainter extends CustomPainter {
  _TooltipBubblePainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 10.0;
    const tailW = 12.0;
    const tailH = 8.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - tailH),
      const Radius.circular(radius),
    );

    final path =
        Path()
          ..addRRect(rrect)
          ..moveTo(22, size.height - tailH)
          ..lineTo(22 + tailW / 2, size.height)
          ..lineTo(22 + tailW, size.height - tailH)
          ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.08), 6, false);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(covariant _TooltipBubblePainter oldDelegate) =>
      fill != oldDelegate.fill || border != oldDelegate.border;
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
            style: AppTypography.inter(
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
              style: AppTypography.inter(
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

/// TOKENS STRIP card — white surface + teal depth glow (showcase spec).
class FxStripCard extends StatelessWidget {
  const FxStripCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TokensStrip.s4),
    this.onTap,
    this.accent,
    this.radius = TokensStrip.rCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = accent ?? Theme.of(context).colorScheme.primary;

    final decoration = BoxDecoration(
      color: isDark ? TokensStrip.cinematicSurface : TokensStrip.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? TokensStrip.glassBorder(dark: true, accent: primary)
            : TokensStrip.borderDefault,
      ),
      boxShadow: isDark
          ? TokensStrip.elevation(4, dark: true, accent: primary)
          : [
              ...TokensStrip.cardShadow(),
              ...TokensStrip.coloredDepthGlow(primary, strength: 0.28),
            ],
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}

/// Section label — uppercase micro type from TOKENS STRIP panels.
class FxStripSectionLabel extends StatelessWidget {
  const FxStripSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TokensStrip.bodyMuted(
        fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
      ).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Section heading — H2 teal hierarchy.
class FxStripSectionTitle extends StatelessWidget {
  const FxStripSectionTitle(this.title, {super.key, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Text(
      title,
      style: TokensStrip.h2(
        color:
            color ??
            BrandPalette.sectionHeading(primary, dark: isDark),
        fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
      ),
    );
  }
}
