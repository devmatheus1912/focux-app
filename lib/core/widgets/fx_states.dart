import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Reusable error state with retry button
class FxErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const FxErrorState({
    super.key,
    this.message = 'Algo deu errado',
    required this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: EagleTokens.bad.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: EagleTokens.bad, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tentar novamente'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable empty state with branded icon
class FxEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const FxEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Adicionar'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Branded loading indicator
class FxLoading extends StatelessWidget {
  const FxLoading({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

/// Skeleton (shimmer) placeholder. Usar como `child:` enquanto dados carregam.
/// Mantém footprint visual da lista para evitar layout shift.
class FxSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry margin;

  const FxSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.margin = EdgeInsets.zero,
  });

  /// Helper para uma linha de lista com avatar circular + 2 linhas de texto.
  static Widget listTile({EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10)}) {
    return Padding(
      padding: padding,
      child: Row(children: [
        const FxSkeleton(height: 40, width: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          FxSkeleton(height: 14, width: 160),
          SizedBox(height: 8),
          FxSkeleton(height: 12, width: 100),
        ])),
      ]),
    );
  }

  @override
  State<FxSkeleton> createState() => _FxSkeletonState();
}

class _FxSkeletonState extends State<FxSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkLine : const Color(0xFFE6E8EE);
    final highlight = isDark ? const Color(0xFF1F2A44) : const Color(0xFFF2F4F8);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: Color.lerp(base, highlight, t),
          ),
        );
      },
    );
  }
}
