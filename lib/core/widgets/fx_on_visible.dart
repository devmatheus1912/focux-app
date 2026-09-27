import 'package:flutter/widgets.dart';

/// Chama [onVisible] cada vez que o filho entra na área visível do scroll
/// mais próximo (pelo menos [fraction] da altura, ou do viewport se o filho for
/// maior). Aba em segundo plano do shell (`TickerMode` desligado) não conta.
class FxOnVisible extends StatefulWidget {
  const FxOnVisible({
    super.key,
    required this.onVisible,
    required this.child,
    this.fraction = 0.5,
  });

  final VoidCallback onVisible;
  final Widget child;
  final double fraction;

  @override
  State<FxOnVisible> createState() => _FxOnVisibleState();
}

class _FxOnVisibleState extends State<FxOnVisible> {
  ScrollPosition? _position;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_check);
      _position = position?..addListener(_check);
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant FxOnVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCheck();
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _scheduleCheck() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());

  void _check() {
    if (!mounted) return;
    final visible =
        TickerMode.valuesOf(context).enabled && _intersectsViewport();
    if (visible && !_visible) widget.onVisible();
    _visible = visible;
  }

  bool _intersectsViewport() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final viewportBox = Scrollable.maybeOf(context)?.context.findRenderObject();
    final viewport =
        viewportBox is RenderBox && viewportBox.hasSize
            ? viewportBox.localToGlobal(Offset.zero) & viewportBox.size
            : Offset.zero & MediaQuery.sizeOf(context);
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final overlap = rect.intersect(viewport);
    if (overlap.isEmpty) return false;
    final alvo =
        (box.size.height < viewport.height
            ? box.size.height
            : viewport.height) *
        widget.fraction;
    return overlap.height >= alvo;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
