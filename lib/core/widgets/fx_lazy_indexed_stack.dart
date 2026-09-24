import 'package:flutter/widgets.dart';

/// [IndexedStack] que só monta cada filho na primeira visita.
///
/// Tabs já abertas ficam vivas (estado/scroll). As demais usam placeholder
/// até o primeiro tap — corta initState/rede das abas ociosas no shell.
class FxLazyIndexedStack extends StatefulWidget {
  const FxLazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FxLazyIndexedStack> createState() => _FxLazyIndexedStackState();
}

class _FxLazyIndexedStackState extends State<FxLazyIndexedStack> {
  final Set<int> _activated = {};

  @override
  void initState() {
    super.initState();
    _mark(widget.index);
  }

  @override
  void didUpdateWidget(covariant FxLazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _activated.removeWhere((i) => i < 0 || i >= widget.children.length);
    }
    _mark(widget.index);
  }

  void _mark(int index) {
    if (widget.children.isEmpty) return;
    _activated.add(index.clamp(0, widget.children.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }
    final current = widget.index.clamp(0, widget.children.length - 1);
    _activated.add(current);

    return IndexedStack(
      index: current,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != current,
            child: TickerMode(
              enabled: i == current,
              child:
                  _activated.contains(i)
                      ? widget.children[i]
                      : const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
